const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const Razorpay = require("razorpay");

admin.initializeApp();
const db = admin.firestore();

// Razorpay Instance (Keys loaded from Firebase Config / Environment)
// Set in Firebase CLI: firebase functions:config:set razorpay.key_id="rzp_test_..." razorpay.key_secret="..."
const razorpayKeyId = process.env.RAZORPAY_KEY_ID || functions.config().razorpay?.key_id || "rzp_test_PLACEHOLDER";
const razorpayKeySecret = process.env.RAZORPAY_KEY_SECRET || functions.config().razorpay?.key_secret || "rzp_secret_PLACEHOLDER";

const razorpay = new Razorpay({
  key_id: razorpayKeyId,
  key_secret: razorpayKeySecret,
});

/**
 * 1. createOrder Cloud Function
 * - Calculates total securely from Firestore products (never trusts client price)
 * - Assigns readable sequential Order # (e.g. 1001, 1002) via atomic counter
 * - Generates 4-digit Delivery OTP
 * - Creates Razorpay order if payment_mode === "ONLINE_RAZORPAY"
 * - Sets 5-minute cancellation window
 */
exports.createOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated to place an order");
  }

  const userId = context.auth.uid;
  const { items, deliveryAddress, paymentMode, substitutionPreference, handwrittenListImageUrl, deliverySlot } = data;

  if (!deliveryAddress || !deliveryAddress.village_id) {
    throw new functions.https.HttpsError("invalid-argument", "Delivery address and village are required");
  }

  // 1. Calculate Server-Side Pricing from Database
  let calculatedSubtotal = 0;
  const verifiedItems = [];

  if (items && items.length > 0) {
    for (const item of items) {
      const productDoc = await db.collection("products").doc(item.product_id).get();
      if (!productDoc.exists) {
        throw new functions.https.HttpsError("not-found", `Product ${item.product_id} not found in database`);
      }

      const productData = productDoc.data();
      let unitPrice = productData.selling_price;
      let variantName = productData.unit_type || "piece";

      // Match specific variant if provided
      if (item.variant_id && productData.variants && productData.variants.length > 0) {
        const matchedVariant = productData.variants.find((v) => v.variant_id === item.variant_id);
        if (matchedVariant) {
          unitPrice = matchedVariant.selling_price;
          variantName = matchedVariant.variant_name;
        }
      }

      const qty = parseInt(item.quantity) || 1;
      const itemTotal = unitPrice * qty;
      calculatedSubtotal += itemTotal;

      verifiedItems.push({
        product_id: item.product_id,
        variant_id: item.variant_id || "default",
        name_en: productData.name_en,
        name_hi: productData.name_hi,
        variant_name: variantName,
        image_url: (productData.images && productData.images.length > 0) ? productData.images[0] : "",
        unit_price: unitPrice,
        ordered_quantity: qty,
        delivered_quantity: qty,
        item_total: itemTotal,
        is_loose_item: productData.is_loose_item || false,
      });
    }
  }

  // Check Minimum Order Value (Default ₹300, except if only handwritten list is attached)
  const storeSettingsDoc = await db.collection("store_config").doc("settings").get();
  const minOrderValue = storeSettingsDoc.exists ? (storeSettingsDoc.data().min_order_value || 300) : 300;
  const deliveryFee = 0; // FREE Delivery

  if (verifiedItems.length > 0 && calculatedSubtotal < minOrderValue && !handwrittenListImageUrl) {
    throw new functions.https.HttpsError("failed-precondition", `Minimum order value is ₹${minOrderValue}`);
  }

  const finalPayable = calculatedSubtotal + deliveryFee;

  // 2. Generate Readable Sequential Order Number (#1001, #1002...) in Firestore Transaction
  const counterRef = db.collection("counters").doc("orders");
  let orderNumber = 1001;

  await db.runTransaction(async (transaction) => {
    const counterDoc = await transaction.get(counterRef);
    if (counterDoc.exists) {
      orderNumber = (counterDoc.data().current_order_number || 1000) + 1;
      transaction.update(counterRef, { current_order_number: orderNumber });
    } else {
      transaction.set(counterRef, { current_order_number: 1001 });
    }
  });

  // 3. Generate 4-digit Delivery OTP
  const deliveryOtp = Math.floor(1000 + Math.random() * 9000).toString();

  // 4. Create Razorpay Order if Online Payment
  let razorpayOrderId = null;
  if (paymentMode === "ONLINE_RAZORPAY" && finalPayable > 0) {
    try {
      const rzpOrder = await razorpay.orders.create({
        amount: Math.round(finalPayable * 100), // In Paise
        currency: "INR",
        receipt: `ORD_${orderNumber}`,
        notes: { user_id: userId, order_number: orderNumber },
      });
      razorpayOrderId = rzpOrder.id;
    } catch (err) {
      throw new functions.https.HttpsError("internal", `Razorpay order creation failed: ${err.message}`);
    }
  }

  // 5. Store Order in Firestore
  const orderId = `ORD_${orderNumber}`;
  const now = admin.firestore.Timestamp.now();
  const cancelUntil = admin.firestore.Timestamp.fromDate(new Date(Date.now() + 5 * 60 * 1000)); // 5 mins

  const userDoc = await db.collection("users").doc(userId).get();
  const userData = userDoc.data() || {};

  const orderData = {
    order_id: orderId,
    order_number: orderNumber,
    customer_id: userId,
    customer_name: userData.name || "Customer",
    customer_phone: userData.phone || context.auth.token.phone_number || "",
    delivery_address: deliveryAddress,
    items: verifiedItems,
    handwritten_list_image_url: handwrittenListImageUrl || null,
    substitution_preference: substitutionPreference || "replace_with_similar",
    delivery_slot: deliverySlot || "ASAP",
    bill_summary: {
      item_total: calculatedSubtotal,
      discount: 0,
      delivery_fee: deliveryFee,
      final_payable_amount: finalPayable,
    },
    payment_mode: paymentMode,
    payment_status: paymentMode === "COD" ? "PENDING" : (razorpayOrderId ? "PENDING" : "PAID"),
    razorpay_order_id: razorpayOrderId,
    razorpay_payment_id: null,
    order_status: paymentMode === "COD" ? "PLACED" : "AWAITING_PAYMENT",
    delivery_otp: deliveryOtp,
    assigned_delivery_boy_id: null,
    assigned_delivery_boy_name: null,
    created_at: now,
    cancel_allowed_until: cancelUntil,
    edit_history: [],
  };

  await db.collection("orders").doc(orderId).set(orderData);

  return {
    order_id: orderId,
    order_number: orderNumber,
    final_payable_amount: finalPayable,
    razorpay_order_id: razorpayOrderId,
    razorpay_key_id: razorpayKeyId,
    delivery_otp: deliveryOtp,
    cancel_allowed_until: cancelUntil.toDate().toISOString(),
  };
});

/**
 * 2. verifyPaymentAndConfirmOrder Cloud Function
 * - Verifies Razorpay HMAC signature on backend
 * - Sets order status to "CONFIRMED"
 */
exports.verifyPaymentAndConfirmOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { orderId, razorpayOrderId, razorpayPaymentId, razorpaySignature } = data;

  const body = razorpayOrderId + "|" + razorpayPaymentId;
  const expectedSignature = crypto
    .createHmac("sha256", razorpayKeySecret)
    .update(body.toString())
    .digest("hex");

  if (expectedSignature !== razorpaySignature) {
    throw new functions.https.HttpsError("permission-denied", "Invalid payment signature verification");
  }

  await db.collection("orders").doc(orderId).update({
    order_status: "CONFIRMED",
    payment_status: "PAID",
    razorpay_payment_id: razorpayPaymentId,
  });

  return { success: true, message: "Payment verified and order confirmed" };
});

/**
 * 3. cancelCustomerOrder Cloud Function
 * - Validates that 5-minute cancellation window has not expired
 */
exports.cancelCustomerOrder = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
  }

  const { orderId, reason } = data;
  const orderDoc = await db.collection("orders").doc(orderId).get();

  if (!orderDoc.exists) {
    throw new functions.https.HttpsError("not-found", "Order not found");
  }

  const order = orderDoc.data();
  if (order.customer_id !== context.auth.uid) {
    throw new functions.https.HttpsError("permission-denied", "You can only cancel your own orders");
  }

  const now = Date.now();
  const cancelAllowedUntil = order.cancel_allowed_until.toDate().getTime();

  if (now > cancelAllowedUntil) {
    throw new functions.https.HttpsError("failed-precondition", "Order cancel window (5 minutes) has expired");
  }

  if (order.order_status === "DELIVERED" || order.order_status === "CANCELLED") {
    throw new functions.https.HttpsError("failed-precondition", "Order cannot be cancelled in current status");
  }

  await db.collection("orders").doc(orderId).update({
    order_status: "CANCELLED",
    cancellation_reason: reason || "Customer cancelled within 5 mins",
  });

  return { success: true, message: "Order cancelled successfully" };
});

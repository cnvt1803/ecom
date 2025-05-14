const pool = require('../models/db');
const emailService = require('../services/emailService');

// iv) Tạo đơn hàng
exports.createOrder = async (req, res) => {
  const { userId, addressId, items, totalAmount } = req.body;
  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    const orderRes = await client.query(`
      INSERT INTO orders (user_id, address_id, total_amount)
      VALUES ($1, $2, $3)
      RETURNING id
    `, [userId, addressId, totalAmount]);

    const orderId = orderRes.rows[0].id;

    for (const item of items) {
      await client.query(`
        INSERT INTO order_items (order_id, product_variant_id, quantity, price_at_time_of_order)
        VALUES ($1, $2, $3, $4)
      `, [orderId, item.variantId, item.quantity, item.price]);
    }

    await client.query('COMMIT');

  // v) Gửi email xác nhận 
    emailService.sendConfirmationEmail(userId, orderId);

     res.status(201).json({
      order_id: orderId,
      status: 'processing',
      total_amount: totalAmount,
      message: 'Order created successfully'
    });
  } catch (error) {
    await client.query('ROLLBACK');
    res.status(500).json({ error: error.message });
  } finally {
    client.release();
  }
};

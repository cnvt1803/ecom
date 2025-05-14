require('dotenv').config();
const sgMail = require('@sendgrid/mail');
const pool = require('../models/db');

sgMail.setApiKey(process.env.SENDGRID_API_KEY);

async function getOrderDetails(userId, orderId) {
  const client = await pool.connect();

  try {
    const userRes = await client.query(
      'SELECT name, email FROM users WHERE id = $1',
      [userId]
    );
    
    const orderRes = await client.query(
      `SELECT o.id, o.total_amount, o.order_date, a.province, a.district, a.commune, a.address_detail
       FROM orders o
       JOIN addresses a ON o.address_id = a.id
       WHERE o.id = $1`, [orderId]
    );
    
    const itemsRes = await client.query(
      `SELECT oi.quantity, oi.price_at_time_of_order, p.name AS product_name, pv.size, pv.color
       FROM order_items oi
       JOIN product_variants pv ON oi.product_variant_id = pv.id
       JOIN products p ON pv.product_id = p.id
       WHERE oi.order_id = $1`, [orderId]
    );

    return {
      user: userRes.rows[0],
      order: orderRes.rows[0],
      items: itemsRes.rows
    };
  } finally {
    client.release();
  }
}

async function sendConfirmationEmail(userId, orderId) {
  try {
    const { user, order, items } = await getOrderDetails(userId, orderId);

    const itemLines = items.map(
      (item) => `
        <li>
          ${item.product_name} (Kích thước: ${item.size}, Màu sắc: ${item.color}) 
          - SL: ${item.quantity} 
          - Đơn giá: ${item.price_at_time_of_order}đ
        </li>`
    ).join('');

    const msg = {
      to: user.email, 
      from: process.env.SENDGRID_FROM_EMAIL, 
      subject: `Xác nhận đơn hàng #${order.id}`,
      html: `
        <h2>Xin chào ${user.name},</h2>
        <p>Cảm ơn bạn đã đặt hàng tại cửa hàng của chúng tôi!</p>
        <p><strong>Mã đơn hàng:</strong> ${order.id}</p>
        <p><strong>Ngày đặt hàng:</strong> ${new Date(order.order_date).toLocaleString()}</p>
        <p><strong>Địa chỉ giao hàng:</strong> ${order.province}, ${order.district}, ${order.commune}, ${order.address_detail}</p>
        <p><strong>Tổng tiền:</strong> ${order.total_amount}đ</p>
        <p><strong>Sản phẩm:</strong></p>
        <ul>${itemLines}</ul>
        <p>Chúng tôi sẽ sớm xử lý đơn hàng của bạn.</p>
      `
    };

    await sgMail.send(msg);
    console.log(`Email xác nhận đã gửi đến ${user.email}`);
  } catch (error) {
    console.error(' Lỗi gửi email:', error.response?.body || error.message);
  }
}

module.exports = { sendConfirmationEmail };

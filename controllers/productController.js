const pool = require('../models/db');

// i) Lấy tất cả danh mục
exports.getAllCategories = async (req, res) => {
  try {
    const result = await pool.query('SELECT * FROM categories');
    res.json(result.rows);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
};

// ii) Lấy sản phẩm theo tên danh mục
exports.getProductsByCategory = async (req, res) => {
  const categoryName = req.params.categoryName;

  try {
    const query = `
      SELECT p.*
      FROM products p
      JOIN categories c ON p.category_id = c.id
      WHERE c.name ILIKE '%' || $1 || '%'
    `;

    const result = await pool.query(query, [categoryName]);

    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Không tìm thấy sản phẩm nào thuộc danh mục phù hợp.' });
    }

    res.status(200).json({
      category: categoryName,
      total: result.rows.length,
      products: result.rows
    });
  } catch (error) {
    console.error('Lỗi khi lấy sản phẩm theo tên danh mục:', error);
    res.status(500).json({ error: 'Lỗi máy chủ. Vui lòng thử lại sau.' });
  }
};

// iii) Tìm kiếm sản phẩm

exports.searchProducts = async (req, res) => {
  const { query, minPrice, maxPrice, sort } = req.query;

  if (!query) {
    return res.status(400).json({ error: "Thiếu từ khóa tìm kiếm (query)" });
  }

  try {
    let sql = `SELECT * FROM products WHERE name ILIKE $1`;
    const values = [`%${query}%`];
    let paramIndex = 2;

    // Lọc theo giá
    if (minPrice) {
      sql += ` AND price >= $${paramIndex++}`;
      values.push(Number(minPrice));
    }

    if (maxPrice) {
      sql += ` AND price <= $${paramIndex++}`;
      values.push(Number(maxPrice));
    }

    if (sort && (sort === 'asc' || sort === 'desc')) {
      sql += ` ORDER BY price ${sort.toUpperCase()}`;
    }

    const result = await pool.query(sql, values);

    res.status(200).json({
      total: result.rows.length,
      products: result.rows,
    });
  } catch (error) {
    console.error("Lỗi khi tìm kiếm sản phẩm:", error);
    res.status(500).json({ error: "Lỗi máy chủ. Vui lòng thử lại sau." });
  }
};

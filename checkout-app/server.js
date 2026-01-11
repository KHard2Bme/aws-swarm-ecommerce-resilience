const express = require("express");
const app = express();

const PORT = 80; // MUST be 80 inside container

app.get("/checkout", (req, res) => {
  res.send(`
    <h1>🧾 Checkout</h1>
    <p>Items in cart:</p>
    <ul>
      <li>Laptop – $999</li>
      <li>Headphones – $199</li>
    </ul>
    <p>Total: <strong>$1198</strong></p>
    <button>Place Order</button>
  `);
});

app.get("/", (req, res) => {
  res.redirect("/checkout");
});

app.listen(PORT, () => {
  console.log(`Checkout running on port ${PORT}`);
});


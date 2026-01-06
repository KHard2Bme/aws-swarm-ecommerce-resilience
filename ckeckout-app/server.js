const express = require("express");
const app = express();

app.get("/", (req, res) => {
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

app.listen(3000, () => {
  console.log("Checkout running on port 3000");
});


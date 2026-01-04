const express = require("express");
const app = express();
const PORT = 80;

app.get("/", (req, res) => {
  res.send("<h1>Welcome to the Frontend Store</h1><p>Products go here!</p>");
});

app.listen(PORT, () => {
  console.log(`Frontend running on port ${PORT}`);
});

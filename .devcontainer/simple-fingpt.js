// simple-fingpt.js
const express = require("express");
const cors = require("cors");
const app = express();
const port = 8080;

app.use(cors());
app.use(express.json());

app.post("/predict", (req, res) => {
  const requestText = req.body.text || "empty request";
  console.log(`Received request: ${requestText}`);

  res.json({
    score: 0.85,
    text: `FinGPT mock response to: ${requestText}`,
  });
});

app.get("/health", (req, res) => {
  res.json({ status: "ok", service: "fingpt-mock" });
});

app.listen(port, "0.0.0.0", () => {
  console.log(`FinGPT mock server listening at http://0.0.0.0:${port}`);
});

module.exports = (req, res, next) => {
  if (req.method === "POST" && req.path === "/predict") {
    req.body = {
      score: 0.85,
      text: `FinGPT response to: ${req.body.text || "empty request"}`,
    };
  }
  next();
};

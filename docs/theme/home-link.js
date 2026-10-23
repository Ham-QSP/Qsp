// Adds a "Home" link to the QSP homepage (the site root, one level above the book).
(function () {
  var root = (typeof path_to_root === "string") ? path_to_root : "";
  var buttons = document.querySelector(".left-buttons");
  if (!buttons) { return; }
  var a = document.createElement("a");
  a.href = root + "../";
  a.className = "icon-button";
  a.title = "QSP homepage";
  a.setAttribute("aria-label", "QSP homepage");
  a.textContent = "Home";
  a.style.cssText = "padding:0 8px;font-weight:600;text-decoration:none;display:inline-flex;align-items:center";
  buttons.appendChild(a);
})();

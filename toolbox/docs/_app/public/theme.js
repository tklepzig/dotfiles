const addToggleThemeListener = (selector) => {
  const root = document.documentElement;

  document.querySelector(selector).addEventListener("click", () => {
    if (root.getAttribute("data-theme") == "light") {
      localStorage.setItem("theme", "dark");
      root.setAttribute("data-theme", "dark");
    } else {
      localStorage.setItem("theme", "light");
      root.setAttribute("data-theme", "light");
    }
  });
};

(() => {
  const getTheme = () => {
    if (localStorage.getItem("theme")) {
      return localStorage.getItem("theme");
    }

    if (!window.matchMedia) {
      return "light";
    }

    if (window.matchMedia("(prefers-color-scheme: dark)").matches) {
      return "dark";
    }
  };

  if (getTheme() == "dark") {
    document.documentElement.setAttribute("data-theme", "dark");
  }
})();

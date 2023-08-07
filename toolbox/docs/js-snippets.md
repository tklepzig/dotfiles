# JavaScript Snippets

## GitHub

Mark all viewed files in a PR as unviewed

    document.querySelectorAll('.js-reviewed-checkbox[checked]').forEach(c => c.click())

Hide checked tasks in issue

    [...document.getElementsByClassName("task-list-item-checkbox")].filter(({checked}) => checked).forEach(({ parentElement }) => parentElement.style.display = "none")

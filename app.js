document.addEventListener("DOMContentLoaded", function () {
    // Close notification messages.
    document.querySelectorAll(".dismiss").forEach(function (button) {
        button.addEventListener("click", function () {
            const message = button.closest(".flash");
            if (message) {
                message.remove();
            }
        });
    });

    // Search/filter rows in the book catalogue.
    const search = document.getElementById("table-search");
    const table = document.getElementById("books-table");

    if (search && table) {
        search.addEventListener("input", function () {
            const query = search.value.toLowerCase();

            table.querySelectorAll("tbody tr").forEach(function (row) {
                row.hidden = !row.innerText.toLowerCase().includes(query);
            });
        });
    }
});
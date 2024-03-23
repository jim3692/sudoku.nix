{ table, solution }@data: ''<html>

  <head>
    <title>NixOS Sudoku Solver</title>

    <style>
      table, td {
        border: 1px solid black;
        border-collapse: collapse;
      }

      td {
        height: 24px;
        width: 24px;

        font-family: monospace;
        font-size: 20px;

        text-align: center;
        align-content: center;

        user-select: none;

        color: blue;
      }

      td.from-table {
        color: black;
      }
    </style
  </head>

  <body>
    <table id="board"></table>
    <script>
      const { table, solution } = ${builtins.toJSON data};
      const board = document.getElementById("board");

      const rows = [...Array(9)].map(_ => document.createElement("tr"));

      rows.forEach(r => {
        const cells = [...Array(9)].map(_ => document.createElement("td"));
        cells.forEach(c => r.appendChild(c));
      });

      rows.forEach(r => document.body.appendChild(r));

      const cells = document.querySelectorAll("td");
      cells.forEach((c, idx) => { c.innerText = solution[idx]; })
      cells.forEach((c, idx) => {
        if (table[idx]) {
          c.className = "from-table";
        }
      })
    </script>
  </body>

</html>''

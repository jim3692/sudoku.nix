{ tableToSolve, lib }: with builtins; let
  SQUARE_MAPPING = with lib.lists;
    let
      incSort = sort (a: b: a < b);
      squaresLine = n: flatten (replicate 3 (range n (n + 2)));
      squaresChunk = n: replicate 3 (incSort (squaresLine n));
    in flatten [
      (squaresChunk 0)
      (squaresChunk 3)
      (squaresChunk 6)
    ];

  modulo = a: b: a - (a / b) * b;
  modulo9 = a: modulo a 9;

  pipeline = p: d: lib.foldl' (data: cb: cb data) d p;
  flattenAndUnique = d: with lib.lists; pipeline [ flatten unique ] d;

  listContains = i: l: (length l) > (length (lib.lists.subtractLists [ i ] l));

  appendToNthList = v: n: l: with lib.lists;
    let
      chunk1 = take (n + 1) l;
      chunk1rev = reverseList chunk1;
      chunk1tail = head chunk1rev;
      chunk1head = reverseList (tail chunk1rev);
      chunk2 = drop (n + 1) l;
    in
      chunk1head ++ [ (chunk1tail ++ [ v ]) ] ++ chunk2;

  getNthItem = n: l: head (lib.lists.sublist n 1 l);
  setNthItem = n: v: l: lib.lists.imap0 (i: v': if i == n then v else v') l;

  appendToLastList = v: l:
    appendToNthList v ((length l) - 1) l;

  tableGroubBy = callback: t: (lib.foldl' (acc: v: {
    index = acc.index + 1;
    result = callback acc v;
  }) { index = 0; result = lib.lists.replicate 9 []; } t).result;

  groubByRow = t: tableGroubBy (acc: v:
    appendToNthList v (acc.index / 9) acc.result
  ) t;

  groubByColumn = t: tableGroubBy (acc: v:
    appendToNthList v (modulo9 acc.index) acc.result
  ) t;

  groubBySquare = t: tableGroubBy (acc: v:
    appendToNthList v.fst v.snd acc.result
  ) (lib.lists.zipLists t SQUARE_MAPPING);

  findEmptyShells = t: lib.filter (s: s == 0) t;

  getRowByIndex = t: n: getNthItem (n / 9) (groubByRow t);
  getColumnByIndex = t: n: getNthItem (modulo9 n) (groubByColumn t);
  getSquareByIndex = t: n: getNthItem (getNthItem n SQUARE_MAPPING) (groubBySquare t);

  getNotes = t: with lib.lists;
    imap0 (i: v: {
      index = i;
      notes =
        if v > 0
        then []
        else subtractLists
          (unique (flatten [
            (getRowByIndex t i)
            (getColumnByIndex t i)
            (getSquareByIndex t i)
          ]))
          (range 1 9);
    }) t;

  getRefinedNotesByGroup = gn: an: with lib.lists;
    let
      filteredNotes = imap0 (_: v: filter (n': (length n'.notes) > 0) v) gn;
      notesPerRow = imap0 (_: v: flattenAndUnique (imap0 (_: n': n'.notes) v)) filteredNotes;
      cellsPerNumber = imap0 (i: rowNotes:
        let
          row = getNthItem i filteredNotes;
          findCellsWithNum = num: filter (cell: listContains num cell.notes) row;
          extractIdxs = cells: imap0 (_: cell: cell.index) cells;
        in imap0 (_: num: {
          number = num;
          cells = extractIdxs (findCellsWithNum num);
        }) rowNotes
      ) notesPerRow;
      singulars = filter (cn: (length cn.cells) == 1) (flatten cellsPerNumber);

      updateNotes = notes: s:
        let
          firstSingular = head s;
          firstSingularNumber = firstSingular.number;
          firstSingularIdx = head firstSingular.cells;
          restSingulars = tail s;
        in
          if (length s) > 0
          then imap0 (i: n: if i == firstSingularIdx then { index = i; notes = [ firstSingularNumber ]; } else n) (updateNotes notes restSingulars)
          else notes;
    in
      updateNotes an singulars;

  getRefinedNotesByRow = n: getRefinedNotesByGroup (groubByRow n) n;
  getRefinedNotesByColumn = n: getRefinedNotesByGroup (groubByColumn n) n;
  getRefinedNotesBySquare = n: getRefinedNotesByGroup (groubBySquare n) n;

  solveTable = t:
    let
      notes = getNotes t;
      refinedNotes = pipeline [ getRefinedNotesByRow getRefinedNotesByColumn getRefinedNotesBySquare ] notes;
      singulars = filter (n: (length n.notes) == 1) refinedNotes;

      fillCells = table: s:
        let
          firstSingular = head s;
          firstSingularNumber = head firstSingular.notes;
          firstSingularIdx = firstSingular.index;
          restSingulars = tail s;
        in
          if (length s) > 0
          then fillCells (setNthItem firstSingularIdx firstSingularNumber table) restSingulars
          else table;

      updatedCells =
        if (length singulars) > 0
        then fillCells t singulars
        else throw "No possible singulars in ${toJSON t}";
    in updatedCells;

  getSolution = t: if (length (findEmptyShells t)) == 0 then t else (getSolution (solveTable t));
  solution = getSolution tableToSolve;
in solution

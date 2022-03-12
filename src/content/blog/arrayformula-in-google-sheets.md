Fun Google Sheets thing I learned this morning:

https://support.google.com/docs/answer/3093275?hl=en

NB: 'range' and 'array' are used interchangeably.


So, say you have a column of values in A, and you want to do something with those in B. That something in this example will be quoting the values.

My old way would be to create a formula ie. `=CONCATENATE("'",A1,"'")` and filling it down to all the rows where there's something in A. This is fine, but there are two problems: 1. if you accidentally type in one of the cells in B, your calculated value will be blatted and 2. if you add new items in A, you also need to fill down more in B.

Enter `ARRAYFORMULA`.

In `B1`, you could set the formula `=ARRAYFORMULA(CONCAT(CONCAT("'",A:A),"'"))`. This will then perform the formula for every item in column `A` and place it into `B1:B`. (Yes, the double concat is clunky. CONCATENATE already supports arrays `A:A`, so it just shoves it into one long list. concat only supports 2 values, so it works for this)

Problem, though, this formula will also be applied to empty cells. No worries, though: `FILTER` to the rescue. FILTER allows you to filter items out of an array based on a condition, leaving our final formula as  `=ARRAYFORMULA(CONCAT(CONCAT("'",FILTER(A:A,A:A<>"")),"'"))`. (In Excel formulas, `=` is equals, `<>` is not equals)

The end result of this is a column filled with the values of that formula. If you overwrite one of them (except the topmost one) it will automatically fix itself, and if you add more values to A, a new Item will be added in B.

A nice extra bonus is that the cells with the formulas in can be protected, so they aren't updated accidentally. With the 'old' way, you'd then need to protect every new row that was added.

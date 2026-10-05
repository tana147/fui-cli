function sumFooterTable() {}
function generateFakeQRReportVNDate(
  startDateStr,
  endDateStr,
  entriesPerDate = 1
) {
  function randomInt(min, max) {
    return Math.floor(Math.random() * (max - min + 1)) + min;
  }
  function calcTyLeQR(quet, tong) {
    return tong === 0 ? "0%" : `${Math.round((quet / tong) * 100)}%`;
  }
  function formatDateDDMMYYYY(date) {
    const dd = String(date.getDate()).padStart(2, "0");
    const mm = String(date.getMonth() + 1).padStart(2, "0");
    const yyyy = date.getFullYear();
    return `${dd}/${mm}/${yyyy}`;
  }
  function generateDateArray(startStr, endStr) {
    const start = new Date(startStr);
    const end = new Date(endStr);
    const result = [];
    while (start <= end) {
      result.push(new Date(start)); // clone
      start.setDate(start.getDate() + 1);
    }
    return result.map((e) => ({
      Ngay: formatDateDDMMYYYY(e)
    })).flat();
  }
  const giaoDiens = ["Web", "App"];
  const dates = generateDateArray(startDateStr, endDateStr);
  const dataByDate = dates.map((date) => {
    const records = Array.from({ length: entriesPerDate }, () => {
      const tongQR = randomInt(100, 200);
      const quetQR = randomInt(40, tongQR);
      const xem3s = randomInt(30, 100);
      const bamChuyen = randomInt(30, 100);
      const tyLeQR = calcTyLeQR(quetQR, tongQR);
      const giaoDien = giaoDiens[randomInt(0, 1)];
      return { Ngay: date.Ngay , tongQR, quetQR, xem3s, bamChuyen, tyLeQR, giaoDien };
    });
    return records;
  }).flat();
  return [ dates,  dataByDate ];
}
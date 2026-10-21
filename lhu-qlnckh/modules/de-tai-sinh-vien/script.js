 function getKhoaNCKH() {
     ajaxCALL("https://tapi.lhu.edu.vn/hoso/Public_SelectKhoa", null,(res) => {
         vueData.KhoaNCKH = res.data
     }, (err) => {
     })
 }
function test() {
    console.log("123")
}
// let descriptionMeta = document.querySelector('meta[name="viewport"]');
// if (descriptionMeta) {
//     descriptionMeta.content = 'width=device-width, initial-scale=1, maximum-scale=1, user-scalable=no, minimal-ui, viewport-fit=cover';
// }
let viewportMeta = document.querySelector('meta[name="viewport"]');
if (viewportMeta) {
    viewportMeta.content = 'width=device-width, initial-scale=1, maximum-scale=5, user-scalable=yes';
}
function initPage() {
    console.log('vueData.name', vueData.name)
    if (vueData.name) {
        const storeBook = vueData.storeMapping.find(x => x.name === vueData.name);
        vueData.MenuBookID = storeBook?.MenuBookID ?? 0;
        vueData.CuaHangID = storeBook?.CuaHangID ?? 0;
    }
}
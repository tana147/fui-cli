async function onSave(item) {
  const merchantID = vueData.DSCuaHang.find(
    (x) => x.CuaHangID == vueData.CuaHangID,
  )?.MerchantID;
  // Không cần đồng bộ GRAB → lưu trực tiếp
  if (merchantID == null || item.ChoPhepBan_App == false) {
    return callSaveEorder(item);
  }
  confirm({
    title: "Thao tác này sẽ ảnh hưởng tới món trên GRAB?",
    action: async () => {
      try {
        //  Kiểm tra thời gian đồng bộ từ BACKEND (đảm bảo chính xác)
        const syncInfo = await getTimeLastSync(merchantID);
        if (!syncInfo.canSync) {
          showToast({
            type: "warning",
            title: `Vui lòng đợi ${syncInfo.waitSeconds}s để đồng bộ lại với GRAB, cập nhật gần nhất: ${syncInfo.lastSyncTime}`,
          });
          return;
        }
        //  Chạy song song item + modifier (tối ưu hiệu năng)
        const [isItemSuccess, isModifierSuccess] = await Promise.all([
          callSaveItemGrab(item, merchantID),
          callSaveModifierGrab(item, merchantID),
        ]);
        // Chỉ lưu eOrder khi có ít nhất 1 operation thành công
        if (isItemSuccess || isModifierSuccess) {
          await callSaveEorder(item);
        }
      } catch (error) {
        console.error("Lỗi khi đồng bộ GRAB:", error);
        showToast({
          type: "red",
          title:
            "Đồng bộ GRAB thất bại: " + (error.message || "Lỗi không xác định"),
        });
      }
    },
  });
}
function callSaveModifierGrab(item, merchantID) {
  return new Promise((resolve) => {
    ajaxCALL(
      "/eorder/NhomLoaiLyDiem_Select_BySanPhamID",
      { SanPhamID: item.SanPhamID },
      (response) => {
        const modifiers = Array.isArray(response.data) ? response.data : [];
        const isUnavailable = item.TinhTrang == 0;
        // Trường hợp không có modifier → cập nhật chính item như modifier
        if (modifiers.length === 0) {
          saveSingleModifier({
            merchantID,
            isUnavailable,
            maxStock: isUnavailable ? null : Number(item.SoLuongTon),
            name: item.TenSanPham,
            id: item.SanPhamID.toString(),
          }).then(resolve);
          return;
        }
        // Xử lý nhiều modifier song song
        const modifierPromises = modifiers.map((element) =>
          saveSingleModifier({
            merchantID,
            isUnavailable,
            maxStock: isUnavailable ? null : Number(item.SoLuongTon),
            name: item.TenSanPham,
            id: `CUP_${element.NhomLoaiLyDiemID}`,
          }),
        );
        Promise.all(modifierPromises)
          .then((results) => resolve(results.every((r) => r === true)))
          .catch(() => resolve(false));
      },
    );
  });
}
function saveSingleModifier({ merchantID, isUnavailable, maxStock, name, id }) {
  return new Promise((resolve) => {
    const params = {
      merchantID,
      availableStatus: isUnavailable ? "UNAVAILABLE" : "AVAILABLE",
      maxStock,
      field: "MODIFIER",
      name,
      id,
    };
    ajaxCALL(
      "/eorder/GRABPUSH_menu_Update",
      { Json_Data: JSON.stringify(params) },
      (response) => {
        // Xử lý lỗi GRAB 409 (conflict)
        if (response.httpErrorCode === 409) {
          showToast({
            type: "red",
            title:
              "GRAB ERROR: " +
              (response.responseData?.message || "Xung đột dữ liệu"),
          });
          return resolve(false);
        }
        // có responseData = thất bại
        if (response.responseData) {
          return resolve(false);
        }
        // Không có lỗi → thành công
        resolve(true);
      },
    );
  });
}
function callSaveItemGrab(item, merchantID) {
  return new Promise((resolve) => {
    const isUnavailable = item.TinhTrang == 0;
    const params = {
      merchantID,
      maxStock: isUnavailable ? null : Number(item.SoLuongTon),
      availableStatus: isUnavailable ? "UNAVAILABLE" : "AVAILABLE",
      field: "ITEM",
      id: item.SanPhamID.toString(),
    };
    ajaxCALL(
      "/eorder/GRABPUSH_menu_Update",
      { Json_Data: JSON.stringify(params) },
      (response) => {
        if (response.httpErrorCode === 409) {
          showToast({
            type: "red",
            title:
              "GRAB ERROR: " +
              (response.responseData?.message || "Xung đột dữ liệu"),
          });
          return resolve(false);
        }
        if (response.responseData) {
          return resolve(false);
        }
        resolve(true);
      },
    );
  });
}
function callSaveEorder(item) {
  return new Promise((resolve) => {
    const params = {
      SanPham_CuaHangID: item.SanPham_CuaHangID,
      TinhTrang: item.TinhTrang,
    };
    ajaxCALL("/eorder/SanPham_Update_TinhTrang", params, () => {
      runAction(vueData.getSanPham);
      webSocket_Send({ group: vueData.webSocket_Menu, data: Date.now() });
      resolve(true);
    });
  });
}
function getTimeLastSync(merchantID) {
  return new Promise((resolve, reject) => {
    ajaxCALL(
      "/eorder/Grab_Get_TimeLastSync",
      { merchantID: merchantID },
      (res) => {
        if (!res?.data?.[0]) {
          reject(new Error("Không lấy được thông tin đồng bộ GRAB"));
          return;
        }
        const data = res.data[0];
        resolve({
          lastSyncTime: data.LastSyncTime || null,
          canSync: data.CanSync,
          waitSeconds: Number(data.WaitSeconds) || 0,
          timeNow: data.TimeNow,
        });
      },
      (error) => {
        reject(error || new Error("Lỗi kết nối API"));
      },
    );
  });
}
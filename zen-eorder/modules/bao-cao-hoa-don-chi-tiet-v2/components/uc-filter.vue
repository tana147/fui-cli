<template>
	<div>
		<v-row>
			<v-col cols="2">
				<v-select label="Phân hiệu" outlined dense v-model="vueData.PhanHieuID" :items="vueData.DSPhanHieu"
					hide-details item-value="PhanHieuID" item-text="TenPhanHieu" />
			</v-col>
			<v-col cols="2">
				<v-select label="Khu vực" outlined dense v-model="vueData.KhuVucID" :items="vueData.DSKhuVuc"
					hide-details item-value="KhuVucID" item-text="TenKhuVuc" />
			</v-col>
			<v-col cols="3">
				<v-select label="Cửa hàng" multiple outlined dense v-model="vueData.CuaHangIDList"
					:items="CuaHangFilter" item-value="CuaHangID" item-text="TenCuaHang"
					hint="có thể chọn nhiều cửa hàng" persistent-hint
					:menu-props="{ closeOnContentClick: false, maxHeight: 420 }">
					<!-- Nút Chọn tất cả -->
					<template v-slot:prepend-item>
						<v-list-item ripple @click.stop>
							<v-list-item-action>
								<v-checkbox v-model="selectAllModel" :indeterminate="isSomeSelected" color="primary" />
							</v-list-item-action>
							<v-list-item-content>
								<v-list-item-title>Chọn tất cả</v-list-item-title>
							</v-list-item-content>
						</v-list-item>
						<v-divider class="mt-2" />
					</template>


					<!-- Hiển thị lựa chọn gọn -->
					<template v-slot:selection="{ item, index }">
						<span v-if="index < 1">{{ item.TenCuaHang }}</span>
						<span v-if="index === 1" class="primary--text text-caption align-self-center">
							(+{{ vueData.CuaHangIDList.length - 1 }} cửa hàng khác)
						</span>
					</template>
				</v-select>
			</v-col>

			<v-col cols="2">
				<v-select label="Hình thức thanh toán" outlined dense v-model="vueData.HinhThucThanhToan"
					:items="vueData.DSHinhThucThanhToan" hide-details item-value="value" item-text="text" />
			</v-col>
			<v-col cols="2">
				<v-select label="Trạng thái món" outlined dense v-model="vueData.TrangThaiMon"
					:items="vueData.DSTinhTrang" hide-details item-value="value" item-text="text" />
			</v-col>
			<!-- Hình thức thời gian -->
			<v-col cols="3">
				<v-select label="Loại thời gian" outlined dense v-model="vueData.HinhThucThoiGian"
					:items="vueData.DSHinhThucThoiGian" hide-details />
			</v-col>
			<!-- 1: Theo giờ -->
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 1">
				<f-date label="Ngày" outlined dense v-model="vueData.Ngay" :date-add="0" hide-details />
			</v-col>
			<!-- 2: Theo ngày -->
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 2">
				<f-date label="Từ ngày" outlined dense v-model="vueData.TuNgay" :date-add="0" hide-details />
			</v-col>
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 2">
				<f-date label="Đến ngày" outlined dense v-model="vueData.DenNgay" :date-add="0" hide-details />
			</v-col>
			<!-- 3: Theo tuần -->
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 3">
				<v-select label="Năm" outlined dense v-model="vueData.Nam" :items="vueData.DSNam" hide-details />
			</v-col>
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 3">
				<v-select label="Tháng" outlined dense v-model="vueData.Thang" :items="vueData.DSThang" hide-details />
			</v-col>
			<!-- 4: Theo quý || 5: Theo tháng -->
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 4 || vueData.HinhThucThoiGian === 5">
				<v-select label="Năm" outlined dense v-model="vueData.Nam" :items="vueData.DSNam" hide-details />
			</v-col>
			<!-- 6: Theo năm -->
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 6">
				<v-select label="Từ năm" outlined dense v-model="vueData.TuNam" :items="vueData.DSNam" hide-details />
			</v-col>
			<v-col cols="2" v-if="vueData.HinhThucThoiGian === 6">
				<v-select label="Đến năm" outlined dense v-model="vueData.DenNam" :items="vueData.DSNam" hide-details />
			</v-col>
			<v-col cols="2">
				<v-btn color="primary" elevation="0" @click="GetBaoCao()">
					<v-icon left>mdi-filter</v-icon>Tìm
				</v-btn>
			</v-col>
		</v-row>
		<uc-modal-get-data v-model="isOpenModal" />

	</div>
</template>
<script>
export default {
  data() {
    return {
      isOpenModal: false,
      vueData,
    };
  },
  computed: {
    CuaHangFilter() {
      const ds = Array.isArray(this.vueData.DSCuaHang) ? this.vueData.DSCuaHang : [];
      const phanHieu = this.vueData.PhanHieuID;
      const khuVuc   = this.vueData.KhuVucID;

      return ds.filter(item =>
        (item.PhanHieuID === (phanHieu === 0 ? item.PhanHieuID : phanHieu)) &&
        (item.KhuVucID   === (khuVuc   === 0 ? item.KhuVucID   : khuVuc))
      );
    },

    filteredStoreIds() {
      return this.CuaHangFilter.map(x => x.CuaHangID);
    },

    isSomeSelected() {
      const selected = Array.isArray(this.vueData.CuaHangIDList) ? this.vueData.CuaHangIDList : [];
      const total = this.filteredStoreIds.length;
      return selected.length > 0 && selected.length < total;
    },

    selectAllModel: {
      get() {
        const selected = Array.isArray(this.vueData.CuaHangIDList) ? this.vueData.CuaHangIDList : [];
        const total = this.filteredStoreIds.length;
        return total > 0 && selected.length === total;
      },
      set(checked) {
        this.toggleSelectAll(checked);
      }
    }
  },

  watch: {
    'vueData.PhanHieuID'(val) {
      if (val != null) this.vueData.CuaHangIDList = [];
    },
    'vueData.KhuVucID'(val) {
      if (val != null) this.vueData.CuaHangIDList = [];
    }
  },

  methods: {
    toggleSelectAll(checked) {
      if (checked) {
        // chọn tất cả theo danh sách đang lọc
        this.vueData.CuaHangIDList = this.filteredStoreIds.slice();
      } else {
        // bỏ chọn hết
        this.vueData.CuaHangIDList = [];
      }
    },

    GetBaoCao() {
      const count = this.vueData.CuaHangIDList.length;
      if (count === 0)
        return showMessage({ type: "red", title: "Thông báo", message: "Vui lòng chọn ít nhất 1 cửa hàng!" });

      if (count < 2) {
        this.vueData.CuaHangID = this.vueData.CuaHangIDList[0];
        return runAction(this.vueData.getBaoCao);
      }
      this.isOpenModal = true;
    }
  }
}
</script>

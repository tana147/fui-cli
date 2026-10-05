Vue.component("uc-waiting", {
    props: ["ds_hoadon"],
    data() {
        return {
            pageSize: 5,
            currentPage: {
                DSHoaDon_TiepNhan: 1,
                DSHoaDon_CheBien: 1,
                DSHoaDon_HoanThanh: 1,
            },
            intervalId: null,
        };
    },
    computed: {
        // Danh sách theo trạng thái
        DSHoaDon_TiepNhan() {
            return this.ds_hoadon.filter(item => item.TrangThai === 1);
        },
        DSHoaDon_CheBien() {
            return this.ds_hoadon.filter(item => item.TrangThai === 5);
        },
        DSHoaDon_HoanThanh() {
            return this.ds_hoadon.filter(item => item.TrangThai === 2);
        },
        // Danh sách phân trang
        paginated_TiepNhan() {
            return this.paginate(this.DSHoaDon_TiepNhan, this.currentPage.DSHoaDon_TiepNhan);
        },
        paginated_CheBien() {
            return this.paginate(this.DSHoaDon_CheBien, this.currentPage.DSHoaDon_CheBien);
        },
        paginated_HoanThanh() {
            return this.paginate(this.DSHoaDon_HoanThanh, this.currentPage.DSHoaDon_HoanThanh);
        },
    },
    methods: {
        // Hàm phân trang chung
        paginate(data, page) {
            const start = (page - 1) * this.pageSize;
            return data.slice(start, start + this.pageSize);
        },
        // Trang kế tiếp (tự động quay lại đầu)
        nextPage(listName) {
            const totalPages = Math.ceil(this[listName].length / this.pageSize) || 1;
            this.currentPage[listName] =
                this.currentPage[listName] < totalPages
                    ? this.currentPage[listName] + 1
                    : 1;
        },
        // Trang trước
        prevPage(listName) {
            if (this.currentPage[listName] > 1) {
                this.currentPage[listName]--;
            }
        },
        // Tự động đổi trang
        autoPaginate() {
            this.intervalId = setInterval(() => {
                this.nextPage("DSHoaDon_TiepNhan");
                this.nextPage("DSHoaDon_CheBien");
                this.nextPage("DSHoaDon_HoanThanh");
            }, 5000);
        },
    },
    mounted() {
        this.autoPaginate();
    },
    beforeDestroy() {
        clearInterval(this.intervalId);
    },
    template: /*html*/ `
    <div style="color:#fff; font-weight:bold">
      <v-row class="ma-0 row-with-line scroll-page">
        <!-- ĐANG CHUẨN BỊ -->
        <v-col class="border-custom-1 container-box bg-custom-1" cols="4">
          <div class="nav-header title-header-custom-1 bg-custom-1 d-flex justify-center ga-3">
            <v-icon class="icon-bounce" size="larger">mdi-timer-sand</v-icon>
            ĐANG CHUẨN BỊ
          </div>
          <div class="d-flex justify-center flex-wrap pt-1">
            <div
              v-for="item in paginated_TiepNhan"
              :key="item.HoaDonID"
              class="item-bill item-bill-1"
            >
              {{ item.SoCho }}
            </div>
          </div>
        </v-col>
        <!-- ĐANG CHẾ BIẾN -->
        <v-col class="border-custom-2 container-box bg-custom-2" cols="4">
          <div class="nav-header title-header-custom-2 bg-custom-2 d-flex justify-center ga-3">
            <v-icon class="icon-bounce" size="larger">mdi-chef-hat</v-icon>
            ĐANG CHẾ BIẾN
          </div>
          <div class="d-flex justify-center flex-wrap pt-1">
            <div
              v-for="item in paginated_CheBien"
              :key="item.HoaDonID"
              class="item-bill item-bill-2"
            >
              {{ item.SoCho }}
            </div>
          </div>
        </v-col>
        <!-- ĐÃ SẴN SÀNG -->
        <v-col class="border-custom-3 container-box bg-custom-3" cols="4">
          <div class="nav-header d-flex title-header-custom-3 justify-center bg-custom-3 ga-3">
            <v-icon class="icon-bounce" size="larger">mdi-room-service</v-icon>
            ĐÃ SẴN SÀNG
          </div>
          <div class="d-flex justify-center flex-wrap pt-1">
            <div
              v-for="item in paginated_HoanThanh"
              :key="item.HoaDonID"
              class="item-bill item-bill-3"
            >
              {{ item.SoCho }}
            </div>
          </div>
        </v-col>
      </v-row>
      <div class="note-custom">
        Vui lòng đợi số thứ tự của bạn | Please wait for your order number
      </div>
    </div>
  `,
});
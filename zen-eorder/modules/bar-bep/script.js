function reloadOrder() {
  if (vueData.KhuCheBienID) {
    const params = { KhuCheBienID: vueData.KhuCheBienID }
    ajaxCALL("/eorder/HoaDon_Select_ByKhuCheBienId", params, (res) => {
      if (res.data) {
        vueData.DTHoaDon = res.data ?? []
        vueData.DSHoaDon = res.data[0] ?? []
        vueData.DSChiTietHoaDon = res.data[1] ?? []
        vueData.CTCuaHang = res.data[2] ?? []
      }
    })
  }
}
const intervalLoadOrder = setInterval(reloadOrder, 60000) //Load lại thời gian đếm 60s/lần
Vue.component("nav_component", {
  template: /*html*/ `
       <v-row class="v-toolbar__title white--text" dense>
            <v-col cols="6" style="display: flex; align-items: center;">
                <v-icon @click="window.location.href = '/chon-bar-bep'" class="float-left px-3" color="white">mdi-arrow-left</v-icon>
                <v-icon @click="toggleFullScreen()" class="float-left px-3" color="white">mdi-fullscreen</v-icon>
                <span class="ml-5">{{vueData.CTCuaHang[0]?.TenCuaHang}}</span>
            </v-col>
       </v-row>
    `,
})
Vue.component("order_list_component", {
  template: /*html*/ `
        <div class="kitchen-container">
            <v-card v-for="(item, i) in vueData.DSHoaDon" :key="item.HoaDonID" outlined style="min-width: 315px; max-width: 315px; border-color:green; height: fit-content;">
                <order-component :order="item"/>
            </v-card>
        </div>
    `,
})
Vue.component("order-component", {
  props: ["order"],
  data() {
    return {
      orderHeight: 0,
      isScrollOrder: false,
      isShowScrollWarning: false,
    }
  },
  template: /*html*/ `
        <v-card-text style="padding: 7px 7px 35px 7px;">
            <v-row>
                <v-col @click="onClickCompleteAll()" cols="2" :class="TimeAgo > 15 ? 'bg-red py-2' : 'bg-green py-2'"
                    class="d-flex"
                    style="cursor: pointer;text-align:center; justify-content:center; align-items:center">
                    <b style="color:white;font-size: 16px;">{{TimeAgo}}'</b>
                </v-col>
                <v-col cols="3" @click="vueData.CTCuaHang[0].LoaiPhanHieuID !== 2 ? onClickDoingAll() : null"
                    class="text-center py-2 d-flex"
                    style="border-left: 1px solid #fff;cursor: pointer; flex-direction:column; justify-content: center; align-items:center"
                    :style="{'background-color': vueData.CTCuaHang[0].LoaiPhanHieuID !== 2 && IsMangVe ? '#ff5252' : '#4caf50'}"
                >
                    <p class="white--text mb-0" style="font-size: 18px;">
                      <b>
                        <span v-if="order.GrabOrderID">GRAB</span>
                        <span v-if="order.KhachTra_SPF > 0">SPF</span>
                        <span v-if="order.KhachTra_XSM > 0">XSM</span>
                        <span v-if="order.KhachTra_HT1 > 0">HT1</span>
                        <span v-if="order.KhachTra_HT2 > 0">HT2</span>
                        <span v-if="order.KhachTra_HT3 > 0">HT3</span>
                        {{order.MaHoaDon}}
                      </b>
                    </p>
                    <p v-if="IsMangVe" class="mb-0 white--text" style="font-size: 18px;">MV</p>
                </v-col>
                <v-col cols="2" class="py-2 bg-green d-flex" style="border-left: 1px solid #fff; text-align:center; justify-content:center; align-items:center">
                  <span style="color: #fff; font-size: 18px;">{{order.SoCho}}</span>
                </v-col>
                <v-col cols="5" class="text-center py-2"
                    class="d-flex"
                    style="border-left: 1px solid #fff; justify-content:center; align-items:center"
                    :style="{'background-color': vueData.CTCuaHang[0].LoaiPhanHieuID === 2 && IsMangVe ? '#ff5252' : '#4caf50'}"
                >
                    <span v-if="vueData.CTCuaHang[0].LoaiPhanHieuID === 2" style="color:white">
                        <v-icon color="white">mdi-map-marker-outline</v-icon>
                        {{order.TenKhuBan}}
                    </span>
                    <span v-if="vueData.CTCuaHang[0].LoaiPhanHieuID !== 2" style="color:white; display: flex; justify-content: space-between;">
                        <b style="font-size: 14px"><v-icon dense class="mx-1" color="white">mdi-delete-variant</v-icon>{{SummaryQuantity.SumNuoc}}</b>
                        <b style="font-size: 14px"><v-icon dense class="mx-1" color="white">mdi-dots-hexagon</v-icon>{{SummaryQuantity.SumTopping}}</b>
                        <b style="font-size: 14px"><v-icon dense class="mx-1" color="white">mdi-cookie</v-icon>{{SummaryQuantity.SumBanh}}</b>
                    </span>
                </v-col>
            </v-row>
            <v-row
                @scroll="onscroll"
                style="overflow:auto;"
                :style="{
                    height: isScrollOrder ? 'calc(100vh - 200px)' : 'fit-content',
                    'padding-bottom': isScrollOrder ?  '50px' : 'auto'
                }"
                class="scroll-shadows"
                ref="orderItem"
            >
                <v-col cols="12 pa-0 scroll-shadows" >
                    <p
                        v-if="order.GhiChu !== ''"
                        class="mb-0 pl-2"
                        style="font-size:16px"
                        :style="{'background-color': order.Is_DoiBan === 1  ? '#ff5252': '#d5ffd7', 'color': order.Is_DoiBan === 1 ? '#fff' : '#000'}"
                    >
                        {{order.GhiChu}}
                    </p>
                    <template v-for="(product, i) in vueData.DSChiTietHoaDon.filter((props) => (props.OrderGUID === order.OrderGUID && props.Is_SanPham === 1))" :key="product.HoaDonChiTietID">
                        <product_component :product="product" :order="order"/>
                    </template>
                </v-col>
            </v-row>
                <div
                    v-if="isShowScrollWarning"
                    style="position:absolute; bottom: 0; left:0; width:100%; height:25px; background-color:#4caf50; display:flex; justify-content: space-around; align-items: center;"
                >
                    <v-icon color="white" small>mdi-arrow-down-bold-outline</v-icon>
                    <v-icon color="white" small>mdi-arrow-down-bold-outline</v-icon>
                    <v-icon color="white" small>mdi-arrow-down-bold-outline</v-icon>
                    <v-icon color="white" small>mdi-arrow-down-bold-outline</v-icon>
                    <v-icon color="white" small>mdi-arrow-down-bold-outline</v-icon>
                </div>
        </v-card-text>
    `,
  mounted() {
    //Lấy chiều cao của order
    this.isShowScrollWarning = this.$refs.orderItem.offsetHeight >= window.innerHeight - 100
    this.$nextTick(() => {
      const myListHeight = this.$refs.orderItem.offsetHeight
      const windowHeight = window.innerHeight - 100
      if (myListHeight > windowHeight) {
        this.isScrollOrder = true
      }
    })
  },
  computed: {
    IsNhaHang: function () {
      return vueData.CTCuaHang[0].LoaiPhanHieuID === 2
    },
    IsMangVe: function () {
      return this.order.Is_MangVe === 1
    },
    TimeAgo: function () {
      return timeAgo(this.order.NgayThemMoi, this.order.GioThemMoi)
    },
    SummaryQuantity: function () {
      const $this = this
      const detail = vueData.DSChiTietHoaDon.filter((props) => props.OrderGUID === $this.order.OrderGUID)
      let countBanh = 0
      let countNuoc = 0
      let countTopping = 0
      if (detail && detail.length > 0) {
        detail.forEach((itemSP) => {
          if (itemSP.Is_SanPham === 1) {
            if (checkNhomSanPhamIDSumBanh(itemSP.NhomSanPhamID)) {
              countBanh += itemSP.SoLuong
            }
            if (checkNhomSanPhamIDSumNuoc(itemSP.NhomSanPhamID)) {
              countNuoc += itemSP.SoLuong
            }
            if (checkNhomSanPhamIDSumTopping(itemSP.NhomSanPhamID)) {
              countTopping += itemSP.SoLuong
            }
          }
        })
      }
      return {
        SumBanh: countBanh,
        SumNuoc: countNuoc,
        SumTopping: countTopping,
      }
    },
  },
  methods: {
    onscroll(event) {
      const $this = this
      var scrollTop = event.currentTarget.scrollTop
      if (scrollTop + event.currentTarget.offsetHeight >= event.currentTarget.scrollHeight) {
        $this.isShowScrollWarning = false
      } else if (scrollTop <= 0) {
        $this.isShowScrollWarning = true
      } else {
        $this.isShowScrollWarning = true
      }
    },
    updateStatusAll(status) {
      const $this = this
      const order = $this.order
      const products = vueData.DSChiTietHoaDon.filter((props) => props.OrderGUID === order.OrderGUID && props.Is_SanPham === 1)
      const arrProductGuid = []
      if (products) {
        products.forEach((item) => {
          arrProductGuid.push(item.SanPhamGUID)
        })
      }
      const params = {
        HoaDonID: order.HoaDonID,
        TrangThai: status,
        OrderGUID: order.OrderGUID,
        SanPhamGUID: arrProductGuid.join(","),
      }
      ajaxCALL("/eorder/HoaDonChiTiet_Update_TrangThai", params, (res) => {
        webSocket_Send({
          group: vueData.webSocket_Hub_Order,
          data: Date.now(),
        })
        if (res.data) {
          reloadOrder()
        }
      })
      if (!order.GrabOrderID) return // nếu không phải đơn hàng grab thì không cần thực thi đoạn script này
      const paramsGRAB = {
        orderID: order.GrabOrderID,
        markStatus: 1, //Đơn hàng sẵn sàng
      }
      ajaxCALL("/eorder/GRABPUSH_Order_MarkStatus", {
        Json_Data: JSON.stringify(paramsGRAB),
        HoaDonID: order.HoaDonID,
      })
    },
    onClickDoingAll() {
      //1: Đã gửi Bếp-Bar, 2: Đã trả món, 3: Đã đổi món, 4: Chờ xử lý , 5: Đang chế biến, 6: Thu ngân hủy, 7: Bếp xác nhận hủy
      const $this = this
      $this.updateStatusAll(5)
    },
    onClickCompleteAll() {
      //1: Đã gửi Bếp-Bar, 2: Đã trả món, 3: Đã đổi món, 4: Chờ xử lý , 5: Đang chế biến, 6: Thu ngân hủy, 7: Bếp xác nhận hủy
      const $this = this
      $this.updateStatusAll(2)
    },
  },
})
Vue.component("product_component", {
  props: ["product", "order"],
  template: /*html*/ `
        <div :class="'px-2 bg-status-' + (product.Is_SanPham === 1 ? product.TrangThai : '0')"
            @click="onClickDoing()"
            style="position: relative"
        >
            <div v-if="product.TrangThai === 6"
                style=" position: absolute;  width: 100%; height: 100%; right: 0; z-index: 1; display: flex; justify-content: center; align-items: center;">
                <p class="font-weight-bold text-h4 text-center mb-0" style="color:#ff000069">HỦY</p>
            </div>
            <div class="tr-product pt-2">
                <div class="td-product-name-send black--text fs-16" :style="vueData.CTCuaHang[0].LoaiPhanHieuID === 2 ? '' : 'width: 100%'">
                    <b><span v-if="product.SoLuong > 1" class="bg-red span-unit">{{product.SoLuong}}</span> {{product.TenNoiBo}}</b>
                    <small v-if="product.SoThuTu" style="float: right;color:rgba(0, 0, 0, 0.6)">({{calcIndex(product.SoThuTu, product.SoLuong)}})</small>
                </div>
                <div v-if="vueData.CTCuaHang[0].LoaiPhanHieuID === 2" class="td-product-action text-right pr-2 pl-0">
                    <v-btn v-on:click.stop="" @click="onClickComplete()" v-if="product.Is_SanPham === 1 && product.TrangThai !== 2 && product.TrangThai !== 1" fab color="primary" class="bg-white" style="z-index:2" x-small><v-icon>mdi-arrow-right</v-icon></v-btn>
                </div>
            </div>
            <div class="tr-product pb-2" style="border-bottom: 2px dashed rgb(57 119 68);">
                <span class="ml-2">{{product.TenLoaiLy}}</span>
                <template v-for="(detail, i) in vueData.DSChiTietHoaDon.filter((props) => (props.OrderGUID === product.OrderGUID && props.SanPhamGUID === product.SanPhamGUID && props.Is_SanPham === 0))" :key="i">
                    <product_detail_component :detail="detail"/>
                </template>
                <div style="width: 100%" v-if="product.Is_MangVe === 1 || (product.GhiChu && product.GhiChu !== '')" class="pl-3 py-1"><span class="error--text" v-if="product.Is_MangVe === 1 && !product.GrabOrderID">Mang về </span> - {{product.GhiChu}}</span></div>
            </div>
        </div>
    `,
  methods: {
    updateStatus(status) {
      const $this = this
      const oldStatus = $this.product.TrangThai
      $this.product.TrangThai = status //Cập nhật trạng thái mới
      const params = {
        HoaDonID: $this.order.HoaDonID,
        TrangThai: status,
        OrderGUID: $this.product.OrderGUID,
        SanPhamGUID: $this.product.SanPhamGUID,
      }
      ajaxCALL("/eorder/HoaDonChiTiet_Update_TrangThai", params, (res) => {
        webSocket_Send({
          group: vueData.webSocket_Hub_Order,
          data: Date.now(),
        })
        if (res.data) {
          reloadOrder()
        } else {
          $this.product.TrangThai = oldStatus //Đổi về trạng thái cũ nếu lỗi
        }
      })
    },
    onClickDoing() {
      //1: Đã gửi Bếp-Bar, 2: Đã trả món, 3: Đã đổi món, 4: Chờ xử lý , 5: Đang chế biến, 6: Thu ngân hủy, 7: Bếp xác nhận hủy
      const $this = this
      const productItem = $this.product
      if (productItem.TrangThai === 1 || productItem.TrangThai === 5) {
        const status = productItem.TrangThai === 1 ? 5 : 1 //Nếu Đã gửi Bếp-Bar -> Đang chế biến
        $this.updateStatus(status)
      }
    },
    onClickComplete() {
      //1: Đã gửi Bếp-Bar, 2: Đã trả món, 3: Đã đổi món, 4: Chờ xử lý , 5: Đang chế biến, 6: Thu ngân hủy, 7: Bếp xác nhận hủy
      const $this = this
      const productItem = $this.product
      //2: Đã trả món thì không được trả món lần nữa
      if (productItem.TrangThai !== 2) {
        $this.updateStatus(2)
      }
    },
    calcIndex(stt, soLuong) {
      if (!stt) return "";
      const [start, total] = stt.split("/").map(Number);
      const end = start + soLuong - 1;
      if (soLuong === 1) {
        return `${start}/${total}`;
      }
      return `${start}-${end}/${total}`;
    }
  },
})
Vue.component("product_detail_component", {
  props: ["detail"],
  template: /*html*/ `
        <div :class="detail?.NhomLienKetChiTiet_ParentID === null ? 'break-detail' : ''" :style="detail?.SanPhamID > 0 ? 'width: 100%' : ''">
            <div v-if="detail?.SanPhamID > 0">
                <div class="tr-product ml-3">
                    <div class="td-product-name-send color-green"><span v-if="detail.SoLuong > 1" class='bg-red span-unit'>{{detail?.SoLuong}}</span> {{detail?.TenNoiBo}}</div>
                    <div class="td-product-action"></div>
                </div>
            </div>
            <div v-if="detail?.SanPhamID === 0 || detail?.SanPhamID === null">
                <div v-if="detail?.NhomLienKetChiTiet_ParentID !== null || detail?.NhomLienKetChiTiet_ParentID > 0" class="ml-3">
                     {{detail?.TenNoiBo}}
                </div>
            </div>
        </div>
    `,
})
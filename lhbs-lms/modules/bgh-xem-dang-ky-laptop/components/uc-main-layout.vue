<template>
	<Global>
<template #header>
<div class="lap-page-header">
  <div class="lap-header-inner">
    <div class="lap-header-top">
      <div class="lap-header-title-wrap">
        <div class="lap-header-icon-box">
          <v-icon size="28" color="white">mdi-monitor-eye</v-icon>
        </div>
        <div>
          <div class="lap-header-title">{{ TitlePage }}</div>
          <div class="lap-header-subtitle">Theo dõi các lớp đăng kí thiết bị trong khoảng thời gian chọn</div>
        </div>
      </div>
      <div class="lap-header-badges">
        <v-chip color="white" variant="outlined" size="small" prepend-icon="mdi-school">Toàn trường</v-chip>
        <v-chip color="white" variant="tonal" size="small" prepend-icon="mdi-calendar-range">{{ phamViLabel }}</v-chip>
      </div>
    </div>
    <div class="lap-filter-bar">
      <uc-date-range-picker v-model="dateRange" />
      <v-select
        v-model="KhoiItem"
        label="Khối"
        :items="DSKhoi"
        item-title="title"
        return-object
        hide-details
        density="compact"
        variant="outlined"
        class="lap-filter-select"
        bg-color="white"
      />
      <v-select
        v-model="LopItem"
        label="Lớp"
        :items="DSLop"
        item-title="TenLop"
        return-object
        clearable
        hide-details
        density="compact"
        variant="outlined"
        class="lap-filter-select"
        bg-color="white"
      />
    </div>
  </div>
</div>
</template>

<div class="lap-body">

  <!-- Metric Cards -->
  <div v-if="items.length" class="lap-metric-row">
    <div v-for="m in metrics" :key="m.label" class="lap-metric-card" :class="'lap-metric-' + m.color">
      <div class="lap-metric-icon-wrap">
        <v-icon size="26">{{ m.icon }}</v-icon>
      </div>
      <div class="lap-metric-content">
        <div class="lap-metric-value">{{ m.value }}</div>
        <div class="lap-metric-label">{{ m.label }}</div>
        <div class="lap-metric-note">{{ m.note }}</div>
      </div>
    </div>
  </div>

  <!-- Overview Row -->
  <div class="lap-overview-row">
    <!-- Tình trạng vi phạm -->
    <v-alert :type="items.length ? 'success' : 'info'" variant="tonal" density="comfortable" border="start">
      <div class="font-weight-medium">
        {{ items.length ? (isTodayRange ? 'Hôm nay có ' + items.length + ' lượt đăng kí thiết bị' : 'Trong khoảng thời gian đã chọn có ' + items.length + ' lượt đăng kí thiết bị') : (isTodayRange ? 'Hôm nay chưa có tiết nào đăng kí thiết bị' : 'Trong khoảng thời gian đã chọn chưa có tiết nào đăng kí thiết bị') }}
      </div>
      <div class="text-caption mt-1">
        {{ items.length ? 'Các lớp đăng kí được hiển thị bên dưới để Quản sinh/BGH theo dõi.' : (isTodayRange ? 'Không có lớp cần kiểm tra trong ngày hôm nay.' : 'Không có lớp cần kiểm tra trong khoảng thời gian đã chọn.') }}
      </div>
    </v-alert>
    <v-alert v-if="tongViPham" type="warning" variant="tonal" density="comfortable" border="start" class="mt-2">
      <div class="font-weight-medium">{{ tongViPham }} lượt có vi phạm</div>
      <div class="text-caption mt-1">Kiểm tra chi tiết và cập nhật vi phạm trong danh sách bên dưới.</div>
    </v-alert>
  </div>

  <!-- Data Table -->
  <div v-if="items.length" class="lap-card lap-table-card">
    <div class="lap-card-header lap-table-header">
      <div class="d-flex align-center ga-2">
        <v-icon color="#1976d2" size="20">mdi-format-list-bulleted</v-icon>
        <span class="lap-card-title">Danh sách đăng kí cần giám sát</span>
        <v-chip size="x-small" color="primary" variant="tonal">{{ items.length }} lượt</v-chip>
      </div>
      <span class="lap-table-hint">Lớp · Lịch · Vi phạm</span>
    </div>
    <div class="lap-table-wrap">
      <v-data-table
        :headers="headers"
        :items="items"
        :items-per-page="-1"
        :group-by="[{ key: 'NgayApDungHienThi', order: 'desc' }]"
        hide-default-footer
            no-data-text="Chưa có đăng kí trong phạm vi chọn"
        class="lap-data-table"
      >
        <template #group-header="{ item, columns, toggleGroup, isGroupOpen }">
          <tr class="lap-group-row">
            <td :colspan="columns.length">
              <div class="lap-group-header d-flex align-center">
                <v-btn :icon="isGroupOpen ? 'mdi-chevron-down' : 'mdi-chevron-right'" variant="text" size="small" @click="toggleGroup(item)" />
                <span class="font-weight-medium">{{ item.value }}</span>
                <v-chip size="x-small" color="primary" variant="tonal" class="ml-2">{{ thongKeNgay(item.value).luot }} lượt</v-chip>
                <v-chip size="x-small" color="info" variant="tonal" class="ml-1">{{ thongKeNgay(item.value).hocSinh }} HS</v-chip>
              </div>
            </td>
          </tr>
        </template>
        <template #item.KhoiID="{ item }">
          <v-chip size="x-small" color="blue-grey" variant="tonal">{{ item.KhoiID }}</v-chip>
        </template>
        <template #item.TenLop="{ item }">
          <span class="font-weight-medium">{{ item.TenLop }}</span>
        </template>
        <template #item.TenMonHoc="{ item }">
          <span>{{ getNoiDungDangKy(item) }}</span>
        </template>
        <template #item.TenGiaoVienDangKy="{ item }">
          <span>{{ getVaiTroDangKy(item) }}: {{ item.TenGiaoVienDangKy || '—' }}</span>
        </template>
        <template #item.LoaiThietBi="{ item }">
          <v-chip size="x-small" color="primary" variant="outlined" prepend-icon="mdi-laptop">{{ item.LoaiThietBi }}</v-chip>
        </template>
        <template #item.SoHocSinh="{ item }">
          <div class="text-center">
            <v-chip size="x-small" color="blue" variant="tonal">{{ item.SoHocSinh }}</v-chip>
          </div>
        </template>
        <template #item.SoViPham="{ item }">
          <div class="text-center">
            <v-chip size="x-small" :color="item.SoViPham > 0 ? 'error' : 'success'" variant="tonal" :prepend-icon="item.SoViPham > 0 ? 'mdi-alert' : 'mdi-check'">
              {{ item.SoViPham }}
            </v-chip>
          </div>
        </template>
        <template #item.TreHanHienThi="{ item }">
          <div class="text-center">
            <v-chip v-if="item.TreHanHienThi" size="x-small" color="warning" variant="tonal" prepend-icon="mdi-clock-alert">{{ item.TreHanHienThi }}</v-chip>
            <span v-else class="text-medium-emphasis">—</span>
          </div>
        </template>
        <template #item.LichHienThi="{ item }">
          <div class="lap-lich-cell">
            <v-icon size="14" color="grey">mdi-clock-outline</v-icon>
            <span>{{ item.LichHienThi }}</span>
          </div>
        </template>
        <template #item.ThaoTac="{ item }">
          <v-btn icon="mdi-eye-outline" variant="text" color="primary" size="small" title="Xem và đánh vi phạm" @click="moChiTiet(item)" />
        </template>
      </v-data-table>
    </div>
    <div class="lap-mobile-list">
      <v-card v-for="item in items" :key="'mobile_' + item.DangKyID" variant="outlined" class="lap-mobile-registration mb-3 pa-3">
        <div class="d-flex align-center">
          <div>
            <div class="text-subtitle-1 font-weight-medium">{{ item.TenLop }}</div>
            <div class="text-caption text-medium-emphasis">Khối {{ item.KhoiID }} · {{ item.LoaiThietBi }}</div>
          </div>
          <v-spacer />
          <v-btn icon="mdi-eye-outline" variant="text" color="primary" size="small" title="Xem và đánh vi phạm" @click="moChiTiet(item)" />
        </div>
        <v-divider class="my-2" />
        <div class="text-body-2 font-weight-medium">{{ getNoiDungDangKy(item) }}</div>
        <div class="text-caption text-medium-emphasis mt-1">{{ item.LichHienThi }}</div>
        <div class="text-caption text-medium-emphasis mt-1">{{ getVaiTroDangKy(item) }}: {{ item.TenGiaoVienDangKy || '—' }}</div>
        <div class="d-flex flex-wrap ga-2 mt-3">
          <v-chip size="small" color="blue" variant="tonal">{{ item.SoHocSinh }} HS</v-chip>
          <v-chip size="small" :color="item.SoViPham > 0 ? 'error' : 'success'" variant="tonal">{{ item.SoViPham }} vi phạm</v-chip>
          <v-chip v-if="item.TreHanHienThi" size="small" color="warning" variant="tonal">{{ item.TreHanHienThi }}</v-chip>
        </div>
      </v-card>
    </div>
  </div>

</div>
<uc-dialog v-model="dialogChiTiet" :title="'Chi tiết đăng kí - ' + (dangKyDangChon?.TenLop || '')" :width="820" done-text="Lưu" :done-loading="isSavingChiTiet" :done-disabled="!chiTietDaThayDoi" @onSubmit="luuTatCaViPham">
  <template #subTitle v-if="dangKyDangChon">{{ dangKyDangChon.TenGiaoVienDangKy }} · {{ dangKyDangChon.LichHienThi }}</template>
  <v-progress-linear v-if="isLoadingChiTiet" indeterminate color="primary" />
  <div v-if="saveStatus" class="text-caption text-success px-5 pt-2">{{ saveStatus }}</div>
  <v-list v-else lines="two" class="py-0">
    <v-list-item v-for="hs in DSHocSinhChiTiet" :key="hs.DangKyHocSinhID" class="lap-detail-row px-5">
      <template #title>{{ hs.HoTen }}</template>
      <template #subtitle>Mã HS: {{ hs.HocSinhID }} · SDB: {{ hs.SoDanhBo }}</template>
      <template #append>
        <div class="lap-violation-controls">
          <v-checkbox v-model="hs.IsViPham" label="Vi phạm" density="compact" hide-details color="warning" @update:model-value="danhDauThayDoi" />
          <v-text-field v-model="hs.GhiChuViPham" density="compact" variant="outlined" hide-details :disabled="!hs.IsViPham" placeholder="Ghi chú vi phạm" @update:model-value="danhDauThayDoi" />
        </div>
      </template>
    </v-list-item>
  </v-list>
  <div v-if="!isLoadingChiTiet && !DSHocSinhChiTiet.length" class="text-medium-emphasis py-8 text-center">Chưa có học sinh trong lượt đăng kí này.</div>
</uc-dialog>
</Global>
</template>

<script>
	export default {
		inject:['snackbarRef','iframeRef'],
		data(){
			const now=new Date(),iso=now.getFullYear()+'-'+String(now.getMonth()+1).padStart(2,'0')+'-'+String(now.getDate()).padStart(2,'0')
			return {
				vueData,
				TitlePage:'Giám sát HS mang Laptop toàn trường',
				DSKhoi:[{title:'Tất cả khối',value:0},...Array.from({length:7},(_,i)=>({title:`Khối ${i+6}`,value:i+6}))],
				KhoiItem:{title:'Tất cả khối',value:0},
				DSTuan:[],
				TuanItem:null,
				// Giữ danh sách lớp gốc để lọc lại mỗi khi khối được thay đổi.
				DSLopAll:[],
				DSLop:[],
				LopItem:{LopID:0,TenLop:'Tất cả lớp'},
				dateRange:{from:iso,to:iso},
				items:[],
				dialogChiTiet:false,
				dangKyDangChon:null,
				DSHocSinhChiTiet:[],
				isLoadingChiTiet:false,
				isSavingChiTiet:false,
				chiTietDaThayDoi:false,
				saveStatus:'',
				headers:[
					{title:'Khối',key:'KhoiID',align:'center',width:70},
					{title:'Lớp',key:'TenLop',width:90},
					{title:'Loại TB',key:'LoaiThietBi',width:110},
          {title:'Nội dung đăng kí',key:'TenMonHoc',width:150},
          {title:'Người đăng kí',key:'TenGiaoVienDangKy',width:170},
					{title:'Ngày áp dụng',key:'NgayApDungHienThi',width:125},
					{title:'Lịch',key:'LichHienThi',align:'center',width:200},
					{title:'Số HS',key:'SoHocSinh',align:'center',width:80},
					{title:'Vi phạm',key:'SoViPham',align:'center',width:90},
					{title:'Trễ hạn',key:'TreHanHienThi',align:'center',width:95},
					{title:'Ghi chú',key:'GhiChu'},
					{title:'Thao tác',key:'ThaoTac',align:'center',width:100}
				]
			}
		},
		mounted(){
			if(typeof IsCheck_NotRoleParent==='function') IsCheck_NotRoleParent(vueData.user)
		},
		watch:{
			'vueData.NienKhoa':{immediate:true,handler(v){if(v)this.loadInitialData()}},
			TuanItem(){this.getDSDangKy()},
			KhoiItem(){
				this.capNhatDSLopTheoKhoi()
				const lopDangChon=Number(this.LopItem?.LopID||0)
				// Khối mới không còn chứa lớp đang chọn thì trả về “Tất cả lớp” để tránh lọc sai.
				if(lopDangChon && !this.DSLop.some(lop=>Number(lop.LopID)===lopDangChon)) this.LopItem={LopID:0,TenLop:'Tất cả lớp'}
				else this.getDSDangKy()
			},
			LopItem(){this.getDSDangKy()},
			dateRange:{deep:true,handler(){this.getDSDangKy()}},
			// Chọn lớp chỉ dùng để khoanh vùng thao tác; bảng vẫn giữ danh sách tổng quan theo khối.
		},
		computed:{
			homNayLabel(){return this.formatDate(new Date())},
			isTodayRange(){return this.dateRange.from===this.dateRange.to&&this.dateRange.from===this.toDateKey(new Date())},
			phamViLabel(){return this.isTodayRange?'Hôm nay':this.formatDate(this.dateRange.from)+' - '+this.formatDate(this.dateRange.to)},
			tongSoHocSinh(){return this.items.reduce((s,i)=>s+Number(i.SoHocSinh||0),0)},
			tongViPham(){return this.items.reduce((s,i)=>s+Number(i.SoViPham||0),0)},
			tongLop(){return new Set(this.items.map(i=>i.LopID||i.TenLop)).size},
			phanBoKhoi(){
				const r={};
				this.items.forEach(i=>{const k=i.KhoiID||'—';r[k]=(r[k]||0)+1});
				return Object.keys(r).sort().map(k=>({khoi:k,count:r[k]}))
			},
			metrics(){
				return [
					{label:'Lượt đăng kí trong phạm vi',value:this.items.length,note:'Các lớp cần đi kiểm tra',color:'blue',icon:'mdi-clipboard-list-outline'},
					{label:'Học sinh',value:this.tongSoHocSinh,note:'Tổng số lượt HS',color:'cyan',icon:'mdi-account-group-outline'},
					{label:'Lớp đang dùng',value:this.tongLop,note:'Có đăng kí thiết bị',color:'green',icon:'mdi-door-open'},
					{label:'Vi phạm',value:this.tongViPham,note:this.tongViPham?'Cần kiểm tra':'Chưa ghi nhận',color:'orange',icon:'mdi-alert-outline'}
				]
			}
		},
			methods:{
				// Chuẩn hóa nhãn hiển thị cho cả dữ liệu GVCN mới và các bản ghi cũ từng lưu “Sinh hoạt”.
				isGVCNDangKy(item){
					const value=String(item?.TenMonHoc||'').trim().toLowerCase()
					return Number(item?.IsGVCN||0)===1||item?.IsGVCN===true||value==='gvcn đăng ký thiết bị'||value==='sinh hoạt (chủ nhiệm)'||value==='sinh hoạt'
				},
				getNoiDungDangKy(item){return this.isGVCNDangKy(item)?'GVCN đăng ký thiết bị':(item?.TenMonHoc||'Chưa xác định nội dung')},
				getVaiTroDangKy(item){return this.isGVCNDangKy(item)?'GVCN':'GVBM'},
			async loadInitialData(){
				const[r,t]=await Promise.all([this.getDSLop(),this.getDSTuan()]);
				this.DSLopAll=r||[];
				this.capNhatDSLopTheoKhoi();
				this.DSTuan=t||[];
				this.TuanItem=this.DSTuan.find(x=>x.Is_Active===1)||this.DSTuan[0]||null
			},
			getDSLop(){return fetchPromise('lms/Lop_Get_ByNienKhoa',{NienKhoa:vueData.NienKhoa})},
			// Danh sách lớp phụ thuộc trực tiếp vào khối; không hiển thị lớp của khối khác.
			capNhatDSLopTheoKhoi(){
				const khoiID=Number(this.KhoiItem?.value||0)
				const dsLop=khoiID?this.DSLopAll.filter(lop=>Number(lop.KhoiID||lop.KhoiId||lop.Khoi)===khoiID):this.DSLopAll
				this.DSLop=[{LopID:0,TenLop:'Tất cả lớp'},...dsLop]
			},
			getDSTuan(){return fetchPromise('lms/TuanHocTap_Get',{NienKhoa:vueData.NienKhoa})},
			async getDSDangKy(){
				if(!vueData.NienKhoa)return;
				const r=await fetchPromise('lms/DangKyMangLaptop_Get',{
					NienKhoa:vueData.NienKhoa,
					TuanHocID:0,
					LopID:this.LopItem?.LopID||0,
					KhoiID:this.KhoiItem?.value||0,
					ViewMode:'BGH'
				});
				this.items=(r||[]).filter(i=>this.isInDateRange(i.NgayApDung)).map(i=>{
					const tiet=Number(i.TietBatDau)===Number(i.TietKetThuc)?String(i.TietBatDau):i.TietBatDau+'-'+i.TietKetThuc;
					const thu=i.Thu===8?'CN':'Thứ '+i.Thu;
					const buoi=({1:'Sáng',2:'Chiều',3:'Tối'})[i.Buoi]||'';
					return{...i,TietHienThi:tiet,LichHienThi:thu+' • '+buoi+' • Tiết '+tiet,NgayApDungHienThi:this.formatDate(i.NgayApDung),TreHanHienThi:i.IsTreHan?'Trễ hạn':''}
				}).sort((a,b)=>String(b.NgayApDung).localeCompare(String(a.NgayApDung))||Number(a.KhoiID||0)-Number(b.KhoiID||0)||String(a.TenLop||'').localeCompare(String(b.TenLop||''),'vi')||Number(a.TietBatDau||0)-Number(b.TietBatDau||0))
			},
			thongKeNgay(ngay){
				const rows=this.items.filter(i=>i.NgayApDungHienThi===ngay)
				return{luot:rows.length,hocSinh:rows.reduce((s,i)=>s+Number(i.SoHocSinh||0),0)}
			},
			async moChiTiet(item){
				this.dangKyDangChon=item;this.dialogChiTiet=true;this.isLoadingChiTiet=true
				this.chiTietDaThayDoi=false;this.saveStatus=''
				try{this.DSHocSinhChiTiet=await fetchPromise('lms/DangKyMangLaptop_HocSinh_Get',{DangKyID:item.DangKyID},{cache:false})||[]}
				finally{this.isLoadingChiTiet=false}
			},
			danhDauThayDoi(){this.chiTietDaThayDoi=true},
			async luuTatCaViPham(){
				this.isSavingChiTiet=true;
				try{await Promise.all(this.DSHocSinhChiTiet.map(hs=>this.luuViPham(hs,!!hs.IsViPham,hs.GhiChuViPham||'')));this.chiTietDaThayDoi=false;this.saveStatus='';this.capNhatSoViPham();this.dialogChiTiet=false}
				finally{this.isSavingChiTiet=false}
			},
			luuViPham(hs,value,note){return fetchPromise('lms/DangKyMangLaptop_DanhDauViPham',{DangKyHocSinhID:hs.DangKyHocSinhID,IsViPham:value,GhiChuViPham:note},{cache:false})},
			capNhatSoViPham(){
				if(!this.dangKyDangChon)return;
				const row=this.items.find(x=>x.DangKyID===this.dangKyDangChon.DangKyID);
				if(row)row.SoViPham=this.DSHocSinhChiTiet.filter(x=>x.IsViPham).length
			},
			toDateKey(v){const d=new Date(v),p=n=>String(n).padStart(2,'0');return d.getFullYear()+'-'+p(d.getMonth()+1)+'-'+p(d.getDate())},
			isInDateRange(v){if(!v)return false;const d=this.toDateKey(v);return d>=this.dateRange.from&&d<=this.dateRange.to},
			formatDate(v){
				if(!v)return'';
				const d=new Date(v),p=n=>String(n).padStart(2,'0');
				return`${p(d.getDate())}/${p(d.getMonth()+1)}/${d.getFullYear()}`
			}
		}
	}
</script>
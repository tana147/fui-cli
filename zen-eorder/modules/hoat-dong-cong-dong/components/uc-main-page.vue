<template>
	<div>
		<div class="bg-green text-white text-center d-flex align-center justify-center">
			<img src="/_cdn/zen-eorder/logo-2025-white.png" width="60" height="60" />
			<h3 class="pl-5">HOẠT ĐỘNG CỘNG ĐỒNG</h3>
		</div>
		<div class="bg-green">
			<div class="rounded-xxl bg-white rounded-b-0 pa-2" style="background-color: #ffffff !important">
				<v-expansion-panels v-model="YearPanel_Open" flat hover>
					<v-expansion-panel v-for="yearItem in DSNamHoatDongCongDong" class="mt-2">
						<v-expansion-panel-header class=" rounded-lg  bg-green panel-header-parent">
							<div class="w-100 text-white font-weight-medium d-flex justify-space-between">
								<span>Năm {{ yearItem.Nam }}</span>
								<v-spacer/>
								<span>{{formatPrice(yearItem.TongTien)}} VNĐ</span>
							</div>
						</v-expansion-panel-header>
						<v-expansion-panel-content class="panel-content-parent">
							<v-expansion-panels class="panel-content" v-model="MonthPanel_Open" multiple flat hover>
								<v-expansion-panel
									v-for="citem in DSHoatDongCongDong.filter((item) => item.Nam == yearItem.Nam)"
									@click="getImageListById(citem)" class="mt-2 border-radius-panel">
									<v-expansion-panel-header
										class="primary--text rounded-lg bg-green-2 panel-header-parent">
										Tháng {{ citem.Thang }}
										<b class="text-right pr-2">{{ formatPrice(citem.TongTienQuy) }} VNĐ</b>
									</v-expansion-panel-header>
									<v-expansion-panel-content class="pa-3">
										<p v-if="citem.MoTa?.length === 0">ĐANG CẬP NHẬT...</p>
										<div class="pb-3 content-preline">
											{{ citem.MoTa }}
										</div>
										<div v-if="!(citem.Thang == ThangHienTai && citem.Nam == NamHienTai)">
											<v-row>
												<v-col v-for="(item, index) in citem.HinhAnh" :key="index"
													class="d-flex child-flex" cols="4">
													<v-img :src="item.FileURL" aspect-ratio="1" class="grey lighten-2"
														@click="handleClick(citem, index)" />
												</v-col>
											</v-row>
										</div>
										<v-overlay :value="overlay">
											<v-carousel :absolute="absolute" hide-delimiters style="width: 100vw"
												:value="indexImg">
												<v-carousel-item v-for="(item, i) in DSImageHoatDongCongDong" :key="i"
													:src="item.FileURL" style="position: relative" class="pa-2">
													<v-btn class="mt-2 me-2" icon color="white" @click="overlay = false"
														style="position: absolute; top: 0; right: 0">
														<v-icon>mdi-close</v-icon>
													</v-btn>
												</v-carousel-item>
											</v-carousel>
										</v-overlay>
									</v-expansion-panel-content>
								</v-expansion-panel>
							</v-expansion-panels>
						</v-expansion-panel-content>
					</v-expansion-panel>
				</v-expansion-panels>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
	    props: [],
	    data() {
	        return {
	            _, //Lodash
	            YearPanel_Open: 0,
	            MonthPanel_Open: [],
	            absolute: true,
	            overlay: false,
	            indexImg: null,
	            DSImageHoatDongCongDong: [],
	            DSHoatDongCongDong: [],
	            DSNamHoatDongCongDong: [],
	            HoatDongCongDongID: null,
	            NamHienTai: new Date().getFullYear(),
	            ThangHienTai: new Date().getMonth() + 1,
	        }
	    },
	    mounted() {
	        this.loadDSHoatDongCongDong()
	    },
	    computed: {},
	    watch: {
	        HoatDongCongDongID: function (val) {
	            if (val) {
	                const params = {
	                    HoatDongCongDongID: val,
	                }
	                // ajaxCALL("/eorder/auth/HoatDongCongDongHinhAnh_Select_ById", params, (res) => {
	                //     this.DSImageHoatDongCongDong = res.data
	                //     let findIndex = this.DSHoatDongCongDong.findIndex((item) => item.HoatDongCongDongID === val)
	                //     this.DSHoatDongCongDong[findIndex]["DSImageHoatDongCongDong"] = res.data
	                // })
	            }
	        },
	        //Xử lý mở panel (mở panel năm hiện tại thì tự động mở 2 MonthPanel_Open tháng hiện tại và tháng trước đó)
	        YearPanel_Open: function (val) {
	            if (val == 0) {
	                this.MonthPanel_Open = this.DSHoatDongCongDong.map((item, index) => index)
	            } else {
	                this.MonthPanel_Open = []
	            }
	        },
	    },
	    methods: {
	        handleClick(item, index) {
	            this.overlay = true
	            this.indexImg = index
	            this.DSImageHoatDongCongDong = this.DSHoatDongCongDong.filter((record) => record.HoatDongCongDongID == item.HoatDongCongDongID)[0].HinhAnh
	        },
	        loadDSHoatDongCongDong() {
	            ajaxCALL("/eorder/auth/HoatDongCongDong_Select", null, (res) => {
	                this.DSHoatDongCongDong = res.data?.map((item) => {
	                    return { ...item,Thang: (item.Thang).toString().padStart(2, '0'), HinhAnh: item.HinhAnh ? JSON.parse(item.HinhAnh) : [] }
	                })
	                this.DSNamHoatDongCongDong = [...new Set(res.data.map(item => item.Nam))]
	                this.DSNamHoatDongCongDong = this.DSNamHoatDongCongDong.map(record => {
	                    let TongTienCuaNam = 0
	                    this.DSHoatDongCongDong.forEach(item => {
	                        if (record == item.Nam) {
	                            TongTienCuaNam += item.TongTienQuy
	                        }
	                    })
	                    return { Nam: record, TongTien: TongTienCuaNam }
	                })
	                this.HoatDongCongDongID = res.data[0].HoatDongCongDongID
	                this.YearPanel_Open = 0
	                this.MonthPanel_Open = res.data.filter(item => item.Nam == res.data[0].Nam).map((item, index) => index)
	            })
	        },
	        getImageListById(record) {
	            this.HoatDongCongDongID = record.HoatDongCongDongID
	        },
	        onClickOutside() {
	            this.overlay = false
	        },
	    },
	}
</script>
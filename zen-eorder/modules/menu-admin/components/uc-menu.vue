<template>
	<div class="custom-scroll-img pt-5" style="height: calc(100vh - 147px); width: calc(100vw - 278px)">
		<div ref="menuDiv" class="custom-img-menu" alt="Menu" style="width: 1282px; height: 1080px"
			@click="getClickPosition" :style="{
                backgroundImage: 'url(' + CTCuaHang.Menu_Url + ')',
                backgroundSize: '100% 100%',
            }">
			<div v-for="(box, index) in ds_sp_menu" :key="index" class="resizable-box" :style="{
				left: box.ViTri_X * scaleFactor + 'px',
				top: box.ViTri_Y * scaleFactor + 'px',
				width: '95px',
				height: '90px',
				backgroundImage: 'url(' + box.AnhSanPham_URL + ')',
				backgroundPosition: 'center',
				}" @mousedown.stop="startDrag($event, index)" @click.stop="editProduct(box)">
				<div class="d-flex" style="position: absolute; flex-direction: column; top: -20px; right: -25px">
					<img v-if="is_bestseller" src="/_cdn/zen-eorder/trang-thai-icon/ic-best-seller.png?v=1" width="45"
						height="40" />
					<img v-if="is_hetmon" src="/_cdn/zen-eorder/trang-thai-icon/ic-het-mon.png?v=1" width="50"
						height="50" />
					<img v-if="is_signature" src="/_cdn/zen-eorder/trang-thai-icon/ic-signature.png?v=2" width="64.3"
						height="44.5" />
				</div>
				<div class="custom-button custom-delete-btn" @click.stop.prevent="onDelete(box)"><v-icon
						style="color:red; font-size:30px">
						mdi-close-circle
					</v-icon></div>
				<div v-for="dir in directions" :key="dir" class="resizer" :class="dir"
					@mousedown.stop="startResize($event, index, dir)"></div>
			</div>
		</div>
		<v-dialog v-model="isModalOpen" width="800">
			<v-card>
				<v-toolbar dense flat>
					<v-toolbar-title>
						{{ isEditing ? "Cập nhật sản phẩm" : "Thêm sản phẩm" }}
					</v-toolbar-title>
					<v-spacer></v-spacer>
					<v-btn icon @click="closeModal">
						<v-icon>mdi-close</v-icon>
					</v-btn>
				</v-toolbar>
				<v-card-text>
					<v-row>
						<v-col cols="12">
							<p style="font-size: 14px; color: black" class="pa-0 ps-2">Vị trí: {{ parseInt(mouseX) }},{{
								parseInt(mouseY) }}</p>
						</v-col>
						<v-col cols="12">
							<v-autocomplete v-model="SanPhamItem" label="Chọn sản phẩm" :items="DSSanPham"
								item-text="text" item-value="value" :return-object="true" hide-details outlined
								dense></v-autocomplete>
						</v-col>
					</v-row>
				</v-card-text>
				<v-card-actions>
					<v-spacer></v-spacer>
					<!-- <v-btn v-if="isEditing" class="custom-button" @click="onDelete()">Xóa</v-btn> -->
					<v-btn class="custom-button" @click="isEditing ? updateProduct() : addNewProduct()">Lưu</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>
	</div>
</template>

<script>
	export default {
		props: ["ct_cuahang", "ds_sp_menu", "ds_sp", "is_signature", "is_bestseller", "is_hetmon"],
		computed: {
			scaleFactor() {
				if (!this.$refs.menuDiv) return 1
				const rect = this.$refs.menuDiv.getBoundingClientRect()
				return rect.width / 1271.66 // 1271.66 là width gốc của background
			},
			CTCuaHang() {
				return this.ct_cuahang[0] ?? {}
			},
			DSSanPham() {
				return this.ds_sp ?? []
			},
		},
		data() {
			return {
				mouseX: 0,
				mouseY: 0,
				isModalOpen: false,
				isEditing: false,
				images: [],
				DSSanPham: [],
				firsttime: true,
				SanPhamItem: null,
				editingProduct: null,
				isDragging: false, // chặn khi kéo mở modal
				dragging: null,
				resizing: null,
				resizeDir: "",
				offsetX: 0,
				offsetY: 0,
				directions: ["top-left", "top", "top-right", "right", "bottom-right", "bottom", "bottom-left", "left"],
			}
		},
		watch: {
			isModalOpen: function (isShow) {
				if (isShow) {
					ajaxCALL(
						"/eorder/SanPham_Select_Dropdown_ByCuaHangId",
						{
							CuaHangID: this.CTCuaHang.CuaHangID,
						},
						(res) => {
							this.DSSanPham = res.data
						},
					)
				}
			},
		},
		mounted() { },
		methods: {
			startDrag(e, index) {
				this.dragging = index
				this.offsetX = e.offsetX
				this.offsetY = e.offsetY
				this.dragMoved = false // dùng cờ mới
				document.addEventListener("mousemove", this.onDrag)
				document.addEventListener("mouseup", this.stopAction)
			},
			onDrag(e) {
				if (this.dragging === null) return
				this.dragMoved = true // đã có drag
				const rect = this.$refs.menuDiv.getBoundingClientRect()
				const box = this.ds_sp_menu[this.dragging]
				const scale = rect.width / 1271.66
	
				box.ViTri_X = (e.clientX - rect.left - this.offsetX) / scale
				box.ViTri_Y = (e.clientY - rect.top - this.offsetY) / scale
			},
			startResize(e, index, direction) {
				this.resizing = index
				this.resizeDir = direction
				this.offsetX = e.clientX
				this.offsetY = e.clientY
				document.addEventListener("mousemove", this.onResize)
				document.addEventListener("mouseup", this.stopAction)
			},
			onResize(e) {
				if (this.resizing === null) return
				const rect = this.$refs.menuDiv.getBoundingClientRect()
				const scale = rect.width / 1271.66
				const dx = (e.clientX - this.offsetX) / scale
				const dy = (e.clientY - this.offsetY) / scale
	
				const box = this.ds_sp_menu[this.resizing]
	
				if (this.resizeDir.includes("right")) box.w += dx
				if (this.resizeDir.includes("left")) {
					box.ViTri_X += dx
					box.w -= dx
				}
				if (this.resizeDir.includes("bottom")) box.h += dy
				if (this.resizeDir.includes("top")) {
					box.ViTri_Y += dy
					box.h -= dy
				}
	
				this.offsetX = e.clientX
				this.offsetY = e.clientY
			},
			stopAction() {
				if (this.dragging !== null) {
					const box = this.ds_sp_menu[this.dragging]
					box.ViTri_X = this.snapToGrid(box.ViTri_X)
					box.ViTri_Y = this.snapToGrid(box.ViTri_Y)
					this.saveBoxPosition(box)
				}
				if (this.resizing !== null) {
					const box = this.ds_sp_menu[this.resizing]
					box.ViTri_X = this.snapToGrid(box.ViTri_X)
					box.ViTri_Y = this.snapToGrid(box.ViTri_Y)
					box.w = this.snapToGrid(box.w)
					box.h = this.snapToGrid(box.h)
					this.saveBoxPosition(box)
				}
	
				// Reset drag/resizing
				this.dragging = null
				this.resizing = null
	
				document.removeEventListener("mousemove", this.onDrag)
				document.removeEventListener("mousemove", this.onResize)
				document.removeEventListener("mouseup", this.stopAction)
			},
			snapToGrid(value, gridSize = 1) {
				return Math.round(value / gridSize) * gridSize
			},
	
			getClickPosition(event) {
				let rect = this.$refs.menuDiv.getBoundingClientRect()
				this.mouseX = event.clientX - rect.left
				this.mouseY = event.clientY - rect.top
				this.isEditing = false
				this.isModalOpen = true
			},
			editProduct(item) {
				if (this.dragMoved) return // nếu vừa drag thì không mở modal
				this.mouseX = item.ViTri_X
				this.mouseY = item.ViTri_Y
				this.SanPhamItem = item.SanPhamID
				this.editingProduct = item
				this.isEditing = true
				this.isModalOpen = true
			},
			addNewProduct() {
				if (this.SanPhamItem) {
					ajaxCALL(
						"/eorder/CuaHangMenu_Insert",
						{
							CuaHangID: this.CTCuaHang.CuaHangID,
							SanPhamID: this.SanPhamItem.value,
							ViTri_X: this.mouseX,
							ViTri_Y: this.mouseY,
						},
						(res) => {
							this.closeModal()
							this.$emit("on_load_menu", null)
						},
					)
				}
			},
			updateProduct() {
				if (this.editingProduct && this.SanPhamItem) {
					ajaxCALL(
						"/eorder/CuaHangMenu_Update",
						{
							CuaHang_MenuID: this.editingProduct.CuaHang_MenuID,
							SanPhamID: this.SanPhamItem.value,
							ViTri_X: this.mouseX,
							ViTri_Y: this.mouseY,
						},
						(res) => {
							this.closeModal()
							this.$emit("on_load_menu", null)
						},
					)
				}
			},
			saveBoxPosition(box) {
				ajaxCALL(
					"/eorder/CuaHangMenu_Update",
					{
						CuaHang_MenuID: box.CuaHang_MenuID,
						SanPhamID: box.SanPhamID,
						ViTri_X: box.ViTri_X,
						ViTri_Y: box.ViTri_Y,
						Width: box.w,
						Height: box.h,
					},
					(res) => { },
				)
			},
			closeModal() {
				this.isModalOpen = false
				this.mouseX = 0
				this.mouseY = 0
				this.SanPhamItem = null
				this.editingProduct = null
				this.isEditing = false
			},
			returnIconUrlSanPham(item) {
				let url = ""
				if (item.Is_BestSeller === 1) url = "/_cdn/zen-eorder/ic-best-seller.png"
				if (item.Is_HetMon === 1) url = "/_cdn/zen-eorder/ic-het-mon.png"
				if (item.Is_Signature === 1) url = "/_cdn/zen-eorder/ic-signature.png"
				return url
			},
			isCheckIconSanPham(item) {
				let flag = false
				if (item.Is_BestSeller === 1) flag = true
				if (item.Is_HetMon === 1) flag = true
				if (item.Is_Signature === 1) flag = true
				return flag
			},
			onDelete(item) {
				const $this = this
				confirm({
					title: `Bạn có chắc muốn xóa <b><i>${item.TenSanPham}</i></b>`,
					action: () => {
						ajaxCALL('/eorder/CuaHangMenu_Delete', {
							CuaHang_MenuID: item.CuaHang_MenuID
						}, (res) => {
							$this.$emit("on_load_menu", null)
						})
					}
				})
			}
		},
	}
</script>
<template>
	<div class="product-row">
		<div class="tr-product">
			<div class="td-product-name font-weight-bold">
				{{index + 1}}. {{product?.TenSanPham}}
				<v-icon class="pl-2" dense v-if="product?.Is_KhuyenMai === 1" color="red">mdi-gift-outline</v-icon>
				<p class="font-weight-light" style="font-size:13px" v-if="product.TienVAT_CuaHang_SanPham > 0">
					VAT: <span class="red--text">{{product.TienVAT_CuaHang_SanPham.toLocaleString('vi-vn')}}</span>
				</p>
			</div>
			<div class="td-product-qty">
				<span v-if="product?.SoLuong !== 1">{{product?.SoLuong}}</span>
			</div>
			<div class="td-product-action">
				<v-icon v-if="product?.Is_ThanhToanZen === 1" color="success">mdi-check</v-icon>
			</div>
			<div class="td-product-price">{{product.Is_KhuyenMai === 0 ? product.ThanhTien?.toLocaleString('vi-vn') : 0}}</div>
		</div>
		<div class="tr-product" style="border-bottom: 1px dashed #177a4b">
			<uc-topping v-for="(topping, i) in product?.ThuocTinh?.filter((item) => (item?.SoLuong > 0))" :key="i"
				:topping="topping" />
			<div style="width: 100%; text-align: left"
				v-if="product?.Is_MangVe === 1 || (product?.GhiChu && product?.GhiChu !== '')" class="pl-5">- Ghi chú:
				{{product?.Is_MangVe === 1 ? 'Mang về - ' : ''}}{{product?.GhiChu}}</span>
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: ['product', 'index'] 
	}
</script>
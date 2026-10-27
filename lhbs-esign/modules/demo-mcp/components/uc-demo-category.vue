<template>
	<v-container fluid class="pa-0 canvas-parchment h-100 min-vh-100" style="min-height: 100vh;">
  <!-- Sub-nav frosted bar -->
  <div class="sub-nav-frosted d-flex align-center px-8">
    <div class="tagline font-weight-bold text-ink">Categories</div>
    <v-spacer></v-spacer>
    <v-btn class="button-primary text-none" rounded="pill" color="#0066cc" elevation="0" @click="openAdd">
      <v-icon start>mdi-plus</v-icon> Thêm mới
    </v-btn>
  </div>

  <!-- Content Grid -->
  <div class="pa-8">
    <div v-if="isLoading" class="text-center pa-16 text-ink-muted-48">
      Đang tải dữ liệu...
    </div>
    <v-row v-else-if="categories && categories.length > 0">
      <v-col cols="12" sm="6" md="4" lg="3" v-for="item in categories" :key="item.CategoryID">
        <v-card class="store-utility-card" elevation="0" rounded="lg">
          <div class="d-flex align-center mb-4">
             <v-avatar :color="item.Color" size="48" class="mr-4" rounded="sm">
               <v-icon color="white" size="24">{{ item.Icon }}</v-icon>
             </v-avatar>
             <div>
                <div class="body-strong text-ink">{{ item.Name }}</div>
                <div class="caption text-ink-muted-80">{{ item.Code }}</div>
             </div>
          </div>
          <v-divider class="mb-4 hairline"></v-divider>
          <div class="d-flex justify-space-between align-center">
            <span class="fine-print text-ink-muted-48">Order: {{ item.SortOrder }}</span>
            <div>
               <v-btn variant="text" size="small" class="text-link mr-2 text-none" @click="openEdit(item)">Sửa</v-btn>
               <v-btn variant="text" size="small" color="error" class="text-none" @click="deleteCategory(item)">Xoá</v-btn>
            </div>
          </div>
        </v-card>
      </v-col>
    </v-row>
    <div v-else class="text-center pa-16 text-ink-muted-48">
      Không có dữ liệu
    </div>
  </div>

  <!-- Dialog Form -->
  <v-dialog v-model="dialog" max-width="500px" persistent>
    <v-card rounded="lg" class="canvas">
      <v-card-title class="display-md text-ink pt-6 px-6">
        {{ form.CategoryID ? 'Sửa Category' : 'Thêm Category' }}
      </v-card-title>
      <v-card-text class="px-6 pt-4">
        <v-text-field v-model="form.Code" label="Mã (Code)" variant="outlined" density="compact" class="mb-4" hide-details></v-text-field>
        <v-text-field v-model="form.Name" label="Tên (Name)" variant="outlined" density="compact" class="mb-4" hide-details></v-text-field>
        <v-row>
          <v-col cols="6">
            <v-text-field v-model="form.Icon" label="Icon" variant="outlined" density="compact" hide-details></v-text-field>
          </v-col>
          <v-col cols="6">
            <v-text-field v-model="form.Color" type="color" label="Màu sắc" variant="outlined" density="compact" hide-details></v-text-field>
          </v-col>
        </v-row>
        <v-text-field v-model.number="form.SortOrder" label="Sắp xếp" type="number" variant="outlined" density="compact" class="mt-4" hide-details></v-text-field>
      </v-card-text>
      <v-card-actions class="px-6 pb-6 pt-0">
        <v-spacer></v-spacer>
        <v-btn class="button-pearl-capsule text-none" variant="flat" color="#fafafc" @click="dialog = false" style="color: #1d1d1f; border: 1px solid #e0e0e0;" :disabled="isSaving">Huỷ</v-btn>
        <v-btn class="button-primary text-none ml-2" variant="flat" color="#0066cc" rounded="pill" @click="saveCategory" :loading="isSaving">Lưu</v-btn>
      </v-card-actions>
    </v-card>
  </v-dialog>
</v-container>
</template>

<script>
	export default {
		name: 'uc-demo-category',
    data() {
        return {
            isLoading: false,
            isSaving: false,
            dialog: false,
            categories: [],
            form: {
                CategoryID: 0,
                Code: "",
                Name: "",
                Icon: "mdi-folder",
                Color: "#0066cc",
                SortOrder: 1
            }
        };
    },
    mounted() {
        this.loadCategories();
    },
    methods: {
        async loadCategories() {
            this.isLoading = true;
            try {
                let rows = await apiCallAsync('WF_Category_GetList', {});
                this.categories = rows || [];
            } catch (err) {
                this.categories = [];
                if (typeof showToast !== 'undefined') {
                    showToast.error(err.responseJSON ? err.responseJSON.Message : 'Lỗi tải danh sách Category.');
                }
            } finally {
                this.isLoading = false;
            }
        },
        openAdd() {
            this.form = { CategoryID: 0, Code: "", Name: "", Icon: "mdi-folder", Color: "#0066cc", SortOrder: 1 };
            this.dialog = true;
        },
        openEdit(item) {
            this.form = { ...item };
            this.dialog = true;
        },
        validateForm() {
            if (!(this.form.Name || '').trim()) return 'Tên không được để trống.';
            if (!(this.form.Code || '').trim()) return 'Mã không được để trống.';
            return '';
        },
        saveCategory() {
            let err = this.validateForm();
            if (err) {
                if (typeof showToast !== 'undefined') showToast.error(err);
                return;
            }
            this.isSaving = true;
            let payload = {
                CategoryID: this.form.CategoryID || 0,
                Code: (this.form.Code || '').trim(),
                Name: (this.form.Name || '').trim(),
                Icon: (this.form.Icon || '').trim(),
                Color: (this.form.Color || '').trim(),
                SortOrder: Number(this.form.SortOrder || 1)
            };
            
            let apiName = payload.CategoryID > 0 ? 'WF_Category_Update' : 'WF_Category_Insert';
            let $this = this;
            
            if (typeof apiCall !== 'undefined') {
                apiCall(apiName, payload, function () {
                    showToast.success(payload.CategoryID > 0 ? 'Cập nhật thành công.' : 'Thêm thành công.');
                    $this.dialog = false;
                    $this.loadCategories().finally(() => { $this.isSaving = false; });
                }, function (xhr) {
                    showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi lưu.');
                    $this.isSaving = false;
                });
            } else {
                this.isSaving = false;
            }
        },
        deleteCategory(item) {
            let $this = this;
            if (typeof showConfirm !== 'undefined') {
                showConfirm('Bạn có chắc chắn muốn xóa category "' + item.Name + '"?', function() {
                    apiCall('WF_Category_Delete', { CategoryID: item.CategoryID }, function() {
                        showToast.success('Xóa thành công.');
                        $this.loadCategories();
                    }, function(xhr) {
                        showToast.error(xhr.responseJSON ? xhr.responseJSON.Message : 'Lỗi khi xóa.');
                    });
                });
            }
        }
    }
	}
</script>
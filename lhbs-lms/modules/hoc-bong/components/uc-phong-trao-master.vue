<template>
	<div class="uc-phong-trao-master">
    <v-card class="mb-3">
      <v-card-title class="d-flex align-center justify-space-between flex-wrap ga-2 py-2 px-3">
        <div class="d-flex align-center ga-2 min-w-0">
          <v-icon color="primary">mdi-format-list-bulleted-type</v-icon>
          <span class="font-weight-bold text-body-1 text-primary text-truncate">Danh mục phong trào thi đua</span>
          <v-chip size="x-small" color="primary" variant="tonal">
            {{ (vueData.DSPhongTraoMaster || []).length }} phong trào
          </v-chip>
        </div>
        <!-- Toolbar chỉ giữ thao tác cấp danh mục; sửa/xóa nằm trên từng dòng tương ứng. -->
        <div class="d-flex align-center ga-1 flex-wrap justify-end">
          <v-btn
            prepend-icon="mdi-refresh"
            variant="outlined"
            class="flex-shrink-0 px-3"
            size="small"
            color="primary"
            :loading="vueData.isLoadingMaster"
            @click="vueData.reloadPhongTraoMaster && vueData.reloadPhongTraoMaster()"
          >
            Làm mới
          </v-btn>
          <v-btn
            v-if="vueData.canViewHocBong !== false"
            prepend-icon="mdi-plus-circle"
            variant="flat"
            class="flex-shrink-0 px-3"
            size="small"
            color="primary"
            @click="vueData.openAddPhongTraoMaster && vueData.openAddPhongTraoMaster()"
          >
            Thêm phong trào
          </v-btn>
        </div>
      </v-card-title>
      <v-card-text class="pa-0">
        <!-- Bảng danh mục phong trào có container cuộn ngang và cuộn dọc chuẩn -->
        <div class="uc-phong-trao-master__table-container">
          <GlobalDataTable
            :headers="tableHeaders"
            :items="prizeRows"
            item-value="rowKey"
            :group-by="[{ key: 'TenPhongTrao', order: 'asc' }]"
            :vDataTableHeight="'min(52dvh, 480px)'"
            items-per-page="-1"
            hide-default-footer
            hover
            class="uc-phong-trao-master__table"
            @click:row="selectRow"
          >
            <template #group-header="{ item, columns, toggleGroup, isGroupOpen }">
              <tr class="uc-phong-trao-master__group-row cursor-pointer" @click="toggleGroup(item)">
                <td :colspan="columns.length" class="py-2">
                  <!-- Khi chi tiết đã tự chọn một phong trào, mở group tương ứng để người dùng thấy dòng giải đang chọn. -->
                  <span v-if="ensureSelectedGroupOpen(item, isGroupOpen, toggleGroup)"></span>
                  <div class="d-flex align-center ga-1">
                    <v-btn
                      :icon="isGroupOpenForItem(item, isGroupOpen) ? 'mdi-chevron-down' : 'mdi-chevron-right'"
                      variant="text"
                      size="x-small"
                      @click.stop="toggleGroup(item)"
                    />
                    <span class="font-weight-bold text-primary text-body-2">{{ item.value }}</span>
                    <v-chip size="x-small" variant="text" color="primary" class="font-weight-regular">
                      ({{ (item.items || []).length }} giải)
                    </v-chip>
                  </div>
                </td>
              </tr>
            </template>

            <!-- Cột chọn radio -->
            <template #item.select="{ item }">
              <div class="d-flex justify-center align-center">
                <v-icon
                  :color="isSelectedPrize(item) ? 'primary' : 'grey-lighten-1'"
                  size="small"
                >
                  {{ isSelectedPrize(item) ? 'mdi-radiobox-marked' : 'mdi-radiobox-blank' }}
                </v-icon>
              </div>
            </template>

            <template #item.TenGiai_VI="{ item }">
              <span class="font-weight-medium text-body-2">{{ item.TenGiai_VI || item.raw?.TenGiai_VI }}</span>
            </template>

            <template #item.TenLoaiMau="{ item }">
              <v-chip size="x-small" color="primary" variant="tonal">
                {{ getTemplateLabel(item.LoaiMau ?? item.raw?.LoaiMau) }}
              </v-chip>
            </template>

            <!-- Cột Thao tác: luôn hiển thị rõ nút Sửa và Xóa phong trào master -->
            <template #item.actions="{ item }">
              <div class="d-flex justify-end align-center ga-1 px-1">
                <template v-if="vueData.canViewHocBong !== false">
                  <v-btn
                    icon="mdi-pencil"
                    size="x-small"
                    variant="text"
                    color="primary"
                    title="Sửa phong trào"
                    aria-label="Sửa phong trào"
                    @click.stop="vueData.openEditPhongTraoMaster && vueData.openEditPhongTraoMaster(item._master || item.raw?._master || item.raw || item)"
                  ></v-btn>
                  <v-btn
                    icon="mdi-delete-outline"
                    size="x-small"
                    variant="text"
                    color="warning"
                    title="Xóa phong trào"
                    aria-label="Xóa phong trào"
                    @click.stop="vueData.openDelPhongTraoMaster && vueData.openDelPhongTraoMaster(item._master || item.raw?._master || item.raw || item)"
                  ></v-btn>
                </template>
                <span v-else class="text-caption text-medium-emphasis">Chỉ xem</span>
              </div>
            </template>

            <template #no-data>
              <div class="text-center py-4 text-grey">Chưa có phong trào nào. Nhấn "Thêm phong trào" để tạo mới.</div>
            </template>
          </GlobalDataTable>
        </div>
      </v-card-text>
    </v-card>

    <uc-dialog
      v-model="vueData.IsShowDialogAddPhongTraoMaster"
      :title="vueData.IsEditingPhongTrao ? 'Cập nhật phong trào thi đua' : 'Thêm mới phong trào thi đua'"
      :width="880"
      done-text="Lưu phong trào"
      :done-loading="vueData.isLoadingSavePhongTrao"
      @onSubmit="vueData.submitSavePhongTraoMaster && vueData.submitSavePhongTraoMaster()"
    >
      <v-row dense class="pt-1">
        <!-- Hàng 1: Tên phong trào & Loại mẫu -->
        <v-col cols="12" sm="8">
          <v-text-field
            v-model="vueData.MasterForm_TenPhongTrao"
            label="Tên phong trào thi đua *"
            placeholder="VD: Cuộc thi Future Hospital Robot..."
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-text-field>
        </v-col>
        <v-col cols="12" sm="4">
          <v-select
            v-model="vueData.MasterForm_LoaiMau"
            :items="vueData.DSLoaiMau"
            item-title="title"
            item-value="value"
            label="Chọn loại mẫu giấy khen *"
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-select>
        </v-col>

        <!--
          Các dòng giấy khen là danh sách cấu hình riêng của phong trào.
          Không bind cố định vào DanhHieu_VI/DanhHieu_EN/NamHoc để có thể thêm dòng mới hoặc bỏ Dòng 3 theo từng mẫu.
        -->
        <v-col cols="12">
          <div class="d-flex align-center justify-space-between mb-2">
            <div class="text-subtitle-2 font-weight-medium text-primary">Các dòng nội dung giấy khen</div>
            <v-btn
              prepend-icon="mdi-plus"
              size="small"
              variant="outlined"
              color="primary"
              @click="vueData.addMasterDongNoiDung && vueData.addMasterDongNoiDung()"
            >
              Thêm dòng
            </v-btn>
          </div>
          <v-alert type="info" variant="tonal" density="compact" class="mb-2">
            Mỗi thẻ bên dưới tương ứng với một dòng trên giấy khen. Thứ tự từ trên xuống là Dòng 1, Dòng 2, Dòng 3...
          </v-alert>
          <v-card
            v-for="(dong, index) in (vueData.MasterForm_DongNoiDung || [])"
            :key="dong.DongID || ('new-dong-' + index)"
            variant="outlined"
            class="mb-2"
          >
            <v-card-text class="pa-2">
              <div class="d-flex align-center flex-wrap ga-2">
                <v-chip size="small" color="primary" variant="tonal">Dòng {{ index + 1 }}</v-chip>
                <span class="text-subtitle-2 font-weight-medium">{{ dong.TenDong || ('Dòng ' + (index + 1)) }}</span>
                <v-chip size="x-small" color="secondary" variant="tonal">{{ getDongLanguageLabel(dong.NgonNgu) }}</v-chip>
                <v-chip v-if="dong.BatBuoc" size="x-small" color="warning" variant="tonal">Bắt buộc</v-chip>
                <v-spacer></v-spacer>
                <v-btn
                  icon="mdi-delete-outline"
                  variant="text"
                  color="warning"
                  :disabled="dong.BatBuoc"
                  :title="dong.BatBuoc ? 'Dòng bắt buộc' : 'Xóa dòng'"
                  :aria-label="dong.BatBuoc ? 'Dòng bắt buộc' : 'Xóa dòng'"
                  @click="vueData.removeMasterDongNoiDung && vueData.removeMasterDongNoiDung(index)"
                ></v-btn>
              </div>
              <v-textarea
                v-model="dong.NoiDung"
                :label="'Nội dung ' + (dong.TenDong || ('Dòng ' + (index + 1))) + (dong.BatBuoc ? ' *' : '')"
                :placeholder="dong.KieuDuLieu === 'school-year' ? 'Năm học/ School Year 2026 - 2027' : 'Nhập nội dung dòng giấy khen...'"
                rows="2"
                auto-grow
                variant="outlined"
                density="compact"
                hide-details="auto"
                class="mt-2"
              ></v-textarea>
              <v-row dense class="mt-1">
                <v-col cols="12" sm="6">
                  <v-text-field
                    v-model="dong.TenDong"
                    label="Tên hiển thị của dòng"
                    placeholder="Dòng 1"
                    variant="outlined"
                    density="compact"
                    hide-details="auto"
                  ></v-text-field>
                </v-col>
                <v-col cols="12" sm="6">
                  <v-select
                    v-model="dong.NgonNgu"
                    :items="vueData.DSNgonNguDong || []"
                    item-title="title"
                    item-value="value"
                    label="Ngôn ngữ của nội dung"
                    variant="outlined"
                    density="compact"
                    hide-details="auto"
                  ></v-select>
                </v-col>
              </v-row>
            </v-card-text>
          </v-card>
          <div v-if="!(vueData.MasterForm_DongNoiDung || []).length" class="text-caption text-medium-emphasis py-2">
            Chưa có dòng nội dung. Nhấn “Thêm dòng” để tạo cấu hình cho mẫu giấy khen.
          </div>
        </v-col>
        <!-- Danh sách giải là tùy chọn; SP Save sẽ đồng bộ chuỗi này vào bảng giải con để danh mục tách được từng giải. Để trống nếu phong trào chỉ có một nhóm chung. -->
        <v-col cols="12">
          <v-text-field
            v-model="vueData.MasterForm_CacGiai"
            label="Các giải thưởng (tùy chọn, cách nhau bởi dấu phẩy)"
            placeholder="VD: Giải Nhất, Giải Nhì, Giải Ba, Giải Khuyến khích..."
            hint="Nhập nhiều giải để danh mục hiển thị theo từng giải; để trống nếu không chia giải."
            persistent-hint
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-text-field>
        </v-col>

        <!-- Phần cuối: Khối áp dụng & Ghi chú -->
        <v-col cols="12" sm="6">
          <v-select
            v-model="vueData.MasterForm_KhoiItem"
            :items="vueData.DSKhoi"
            item-title="title"
            item-value="value"
            return-object
            label="Khối áp dụng"
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-select>
        </v-col>
        <v-col cols="12" sm="6">
          <v-text-field
            v-model="vueData.MasterForm_GhiChu"
            label="Ghi chú"
            placeholder="Ghi chú nội bộ..."
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-text-field>
        </v-col>
      </v-row>
    </uc-dialog>

    <!-- Dialog Xác nhận xóa Phong Trào Master sử dụng uc-dialog -->
    <uc-dialog
      v-model="vueData.IsShowDialogDelPhongTraoMaster"
      title="Xác nhận xóa phong trào"
      :width="520"
      done-text="Xác nhận xóa"
      :done-loading="vueData.isLoadingDelPhongTrao"
      @onSubmit="vueData.submitDelPhongTraoMaster && vueData.submitDelPhongTraoMaster()"
    >
      <div class="py-2 text-body-1">
        Bạn có chắc chắn muốn xóa phong trào <strong>"{{ vueData.itemPhongTraoToDelete?.TenPhongTrao }}"</strong> và toàn bộ danh sách khen thưởng liên quan?
      </div>
    </uc-dialog>

    <!-- Dialog Thêm khen thưởng Chi tiết dùng uc-dialog; từng mẫu chỉ hiển thị đúng dữ liệu cần nhập. -->
    <uc-dialog
      v-model="vueData.IsShowDialogAddChiTietPT"
      :title="'Thêm khen thưởng - ' + (Number(vueData.selectedPhongTrao?.LoaiMau) === 3 ? 'Mẫu 3 · GVCN chọn học sinh lớp chủ nhiệm' : (vueData.selectedPhongTrao?.TenLoaiMau || ''))"
      :width="880"
      done-text="Thêm vào danh sách"
      :done-loading="vueData.isLoadingAddChiTietPT"
      @onSubmit="vueData.submitAddChiTietPT && vueData.submitAddChiTietPT()"
    >
      <div class="pt-1">
        <!-- Mẫu 1: Chỉ lưu/in thông tin lớp; lớp phải lấy từ niên khóa hiện tại để lưu đúng khóa lớp. -->
        <div v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 1">
          <v-alert type="info" variant="tonal" class="mb-2">
            Chọn lớp thuộc niên khóa đang chọn. Mẫu 1 chỉ in thông tin lớp, không lưu học sinh.
          </v-alert>
          <v-autocomplete
            v-model="vueData.DetailForm_LopItem"
            :items="vueData.DSAllLop || []"
            item-title="title"
            item-value="value"
            return-object
            label="Chọn lớp trong niên khóa hiện tại *"
            placeholder="Chọn lớp / Class"
            hint="Danh sách lớp được lấy từ API theo niên khóa hiện tại."
            persistent-hint
            clearable
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-autocomplete>
        </div>

        <!-- Mẫu 2: Lọc khối và chọn học sinh -->
        <div v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 2">
          <v-row dense class="mb-2">
            <v-col cols="12" sm="4">
              <v-select
                v-model="vueData.DetailForm_KhoiItem"
                :items="vueData.DSKhoi"
                item-title="title"
                item-value="value"
                return-object
                label="Lọc học sinh theo khối"
                variant="outlined"
                density="compact"
                hide-details="auto"
                @update:model-value="vueData.onDetailKhoiChange && vueData.onDetailKhoiChange($event)"
              ></v-select>
            </v-col>
            <v-col cols="12" sm="8">
              <v-autocomplete
                v-model="vueData.DetailForm_HocSinhSelected"
                :items="vueData.DSFilteredHocSinh || vueData.DSAllHocSinh"
                item-title="Title"
                return-object
                multiple
                chips
                closable-chips
                clearable
                label="Chọn học sinh (chọn một hoặc nhiều em) *"
                placeholder="Tìm học sinh theo tên / lớp / MSHS..."
                variant="outlined"
                density="compact"
                hide-details="auto"
              ></v-autocomplete>
            </v-col>
          </v-row>
        </div>

        <!-- Mẫu 3: GVCN hoặc Admin thêm học sinh -->
        <div v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 3">
          <v-alert type="info" variant="tonal" class="mb-3">
            Chọn học sinh để khen thưởng. Tên học sinh và lớp được lấy từ dữ liệu niên khóa hiện tại để in giấy khen.
          </v-alert>
          <v-row dense class="mb-2">
            <v-col cols="12" sm="4">
              <v-autocomplete
                v-model="vueData.DetailForm_LopItem"
                :items="vueData.DSFilteredLop || vueData.DSAllLop || []"
                item-title="title"
                item-value="value"
                return-object
                clearable
                label="Lọc theo lớp"
                placeholder="Chọn lớp"
                variant="outlined"
                density="compact"
                hide-details="auto"
                @update:model-value="vueData.onDetailLopChange && vueData.onDetailLopChange($event)"
              ></v-autocomplete>
            </v-col>
            <v-col cols="12" sm="8">
              <v-autocomplete
                v-model="vueData.DetailForm_HocSinhSelected"
                :items="vueData.DSFilteredHocSinh || vueData.DSAllHocSinh || []"
                item-title="Title"
                return-object
                multiple
                chips
                closable-chips
                clearable
                label="Chọn học sinh *"
                placeholder="Tìm học sinh theo tên / lớp / MSHS..."
                variant="outlined"
                density="compact"
                hide-details="auto"
              ></v-autocomplete>
            </v-col>
          </v-row>
        </div>

        <!-- Mẫu tập thể chọn lớp từ DSAllLop đã tải theo niên khóa hiện tại, không cho nhập tên lớp tự do. -->
        <v-alert v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 4" type="info" variant="tonal" class="mb-2">
          Chọn lớp thuộc niên khóa đang chọn. Hệ thống tạo một giấy khen tập thể cho lớp đó.
        </v-alert>
        <v-autocomplete
          v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 4"
          v-model="vueData.DetailForm_TenLop"
          :items="vueData.DSAllLop || []"
          item-title="title"
          item-value="value"
          label="Chọn lớp trong niên khóa hiện tại *"
          placeholder="Chọn lớp / Class"
          hint="Danh sách lớp được lấy theo niên khóa đang chọn."
          persistent-hint
          clearable
          variant="outlined"
          density="compact"
          hide-details="auto"
          class="mb-2"
        ></v-autocomplete>

        <!-- Khung thông tin giấy khen kế thừa theo danh sách dòng động của phong trào -->
        <v-card variant="tonal" color="primary" class="mt-2 pa-3">
          <div class="text-caption text-primary font-weight-bold mb-1">
            THÔNG TIN GIẤY KHEN (KẾ THỪA TỪ PHONG TRÀO):
          </div>
          <div v-for="(dong, index) in getDongRows(vueData.selectedPhongTrao)" :key="dong.DongID || ('detail-dong-' + index)" class="text-body-2 mb-1">
            • <b>{{ dong.TenDong || ('Dòng ' + (index + 1)) }}:</b> {{ dong.NoiDung || '-' }}
          </div>
        </v-card>
      </div>
    </uc-dialog>

    <!-- Dialog Xác nhận xóa mục Khen thưởng Chi tiết sử dụng uc-dialog -->
    <uc-dialog
      v-model="vueData.IsShowDialogDelChiTietPT"
      title="Xác nhận xóa khen thưởng"
      :width="500"
      done-text="Xác nhận xóa"
      :done-loading="vueData.isLoadingDelChiTietPT"
      @onSubmit="vueData.submitDelChiTietPT && vueData.submitDelChiTietPT()"
    >
      <div class="py-2 text-body-1">
        Bạn có chắc chắn muốn xóa mục khen thưởng này không?
      </div>
    </uc-dialog>

    <!-- Dialog Sửa khen thưởng Chi tiết sử dụng uc-dialog -->
    <uc-dialog
      v-model="vueData.IsShowDialogEditChiTietPT"
      :title="'Cập nhật khen thưởng - ' + (Number(vueData.selectedPhongTrao?.LoaiMau) === 3 ? 'Mẫu 3 · GVCN chọn học sinh lớp chủ nhiệm' : (vueData.selectedPhongTrao?.TenLoaiMau || ''))"
      :width="880"
      done-text="Lưu thay đổi"
      :done-loading="vueData.isLoadingSaveEditDetail"
      @onSubmit="vueData.submitSaveEditChiTietPT && vueData.submitSaveEditChiTietPT()"
    >
      <v-row dense class="pt-1">
        <!-- Chọn dòng khen thưởng cần sửa -->
        <v-col cols="12">
          <v-autocomplete
            v-model="vueData.EditDetail_SelectedRecord"
            :items="vueData.DSHocBongDetail"
            item-title="Title"
            return-object
            label="Chọn mục khen thưởng cần sửa *"
            variant="outlined"
            density="compact"
            hide-details="auto"
            class="mb-3"
            @update:model-value="vueData.onSelectEditDetailRecord && vueData.onSelectEditDetailRecord($event)"
          ></v-autocomplete>
        </v-col>

        <!-- Mẫu 2: Lọc học sinh theo khối & Chọn học sinh -->
        <template v-if="vueData.selectedPhongTrao?.LoaiMau === 2">
          <v-col cols="12" sm="4">
            <v-select
              v-model="vueData.EditDetail_KhoiItem"
              :items="vueData.DSKhoi"
              item-title="title"
              item-value="value"
              return-object
              label="Lọc học sinh theo khối"
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="vueData.onEditDetailKhoiChange && vueData.onEditDetailKhoiChange($event)"
            ></v-select>
          </v-col>
          <v-col cols="12" sm="8">
            <v-autocomplete
              v-model="vueData.EditDetail_HocSinhItem"
              :items="vueData.DSEditFilteredHocSinh || vueData.DSAllHocSinh"
              item-title="Title"
              return-object
              clearable
              label="Chọn học sinh *"
              placeholder="Tìm học sinh theo tên / lớp / MSHS..."
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="vueData.onEditDetailHocSinhChange && vueData.onEditDetailHocSinhChange($event)"
            ></v-autocomplete>
          </v-col>
        </template>

        <!-- Mẫu 1 chỉ sửa lớp được chọn từ API niên khóa; không cho sửa thành học sinh hoặc tạo thêm phôi. -->
        <template v-if="Number(vueData.selectedPhongTrao?.LoaiMau) === 1">
          <v-col cols="12">
            <v-autocomplete
              v-model="vueData.EditDetail_LopItem"
              :items="vueData.DSAllLop || []"
              item-title="title"
              item-value="value"
              return-object
              clearable
              label="Chọn lớp trong niên khóa hiện tại *"
              placeholder="Chọn lớp / Class"
              hint="Danh sách lớp được lấy từ API theo niên khóa hiện tại."
              persistent-hint
              variant="outlined"
              density="compact"
              hide-details="auto"
            ></v-autocomplete>
          </v-col>
        </template>

        <!-- Mẫu 3 cho phép sửa học sinh -->
        <template v-if="vueData.selectedPhongTrao?.LoaiMau === 3">
          <v-col cols="12" sm="4">
            <v-autocomplete
              v-model="vueData.EditDetail_LopItem"
              :items="vueData.DSEditFilteredLop || vueData.DSAllLop || []"
              item-title="title"
              item-value="value"
              return-object
              clearable
              label="Lọc theo lớp"
              placeholder="Chọn lớp"
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="vueData.onEditDetailLopChange && vueData.onEditDetailLopChange($event)"
            ></v-autocomplete>
          </v-col>
          <v-col cols="12" sm="8">
            <v-autocomplete
              v-model="vueData.EditDetail_HocSinhItem"
              :items="vueData.DSEditFilteredHocSinh || vueData.DSAllHocSinh || []"
              item-title="Title"
              return-object
              clearable
              label="Chọn học sinh *"
              placeholder="Tìm học sinh..."
              variant="outlined"
              density="compact"
              hide-details="auto"
              @update:model-value="vueData.onEditDetailHocSinhChange && vueData.onEditDetailHocSinhChange($event)"
            ></v-autocomplete>
          </v-col>
        </template>

        <!-- Khi sửa mẫu tập thể, vẫn chọn lại lớp từ danh sách của niên khóa thay vì sửa chuỗi tự do. -->
        <template v-if="vueData.selectedPhongTrao?.LoaiMau === 4">
          <v-col cols="12">
            <v-autocomplete
              v-model="vueData.EditDetail_LopItem"
              :items="vueData.DSAllLop || []"
              item-title="title"
              item-value="value"
              return-object
              clearable
              label="Chọn lớp trong niên khóa hiện tại *"
              placeholder="Chọn lớp / Class"
              hint="Danh sách lớp được lấy theo niên khóa đang chọn."
              persistent-hint
              variant="outlined"
              density="compact"
              hide-details="auto"
            ></v-autocomplete>
          </v-col>
        </template>

        <v-col cols="12">
          <v-textarea
            v-model="vueData.EditDetail_DanhHieu_VI"
            label="Dòng 1: Nội dung chứng nhận (Tiếng Việt) *"
            rows="2"
            auto-grow
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-textarea>
        </v-col>

        <v-col cols="12">
          <v-textarea
            v-model="vueData.EditDetail_DanhHieu_EN"
            label="Dòng 2: Nội dung chứng nhận (Tiếng Anh)"
            rows="2"
            auto-grow
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-textarea>
        </v-col>

        <v-col cols="12" sm="6">
          <v-text-field
            v-model="vueData.EditDetail_VaoSo"
            label="Vào sổ (STT) *"
            type="number"
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-text-field>
        </v-col>

        <v-col cols="12" sm="6">
          <v-text-field
            v-model="vueData.EditDetail_SoQuyetDinhVaKhenThuong"
            label="Số QĐ & Khen thưởng"
            variant="outlined"
            density="compact"
            hide-details="auto"
          ></v-text-field>
        </v-col>
        <v-col cols="12" sm="6">
          <v-text-field v-model="vueData.EditDetail_NgayCap_VI" label="Ngày ký (Tiếng Việt)" variant="outlined" density="compact" hide-details="auto"></v-text-field>
        </v-col>
        <v-col cols="12" sm="6">
          <v-text-field v-model="vueData.EditDetail_NgayCap_EN" label="Ngày ký (Tiếng Anh)" variant="outlined" density="compact" hide-details="auto"></v-text-field>
        </v-col>
      </v-row>
    </uc-dialog>
  </div>
</template>

<script>
	export default {
		data() {
    return {
      vueData,
      selectedPrizeKey: null,
      openingGroupName: null
    }
  },
  computed: {
    tableHeaders() {
      const masters = this.vueData.DSPhongTraoMaster || []
      const maxDong = Math.max(3, ...masters.map(master => this.getDongRows(master).length))
      return [
        { title: '', key: 'select', sortable: false, align: 'center', width: '40px' },
        { title: 'Giải đạt được', key: 'TenGiai_VI', width: '130px' },
        { title: 'Mẫu', key: 'TenLoaiMau', width: '140px' },
        ...Array.from({ length: maxDong }, (_, index) => ({
          title: `Dòng ${index + 1}`,
          key: `Dong_${index + 1}`,
          minWidth: '180px'
        })),
        { title: 'Thao tác', key: 'actions', sortable: false, align: 'end', width: '80px' }
      ]
    },
    prizeRows() {
      // GVCN chỉ được thấy các phong trào Mẫu 3; quyền này được lọc lại ở script/API reload và lặp lại tại UI để không lộ nhầm nhóm khi state khởi tạo chậm.
      const masters = this.vueData.canViewHocBong === false
        ? (this.vueData.DSPhongTraoMaster || []).filter(master => Number(master?.LoaiMau) === 3)
        : (this.vueData.DSPhongTraoMaster || [])
      return masters.flatMap(master => {
        const rawGiai = String(master.CacGiai_VI || '').trim()
        const giaiList = rawGiai ? rawGiai.split(',').map(value => value.trim()).filter(Boolean) : ['-']
        return giaiList.map((TenGiai_VI, index) => {
          const dongValues = this.getDongRows(master).reduce((result, dong, dongIndex) => {
            result[`Dong_${dongIndex + 1}`] = dong.NoiDung || ''
            return result
          }, {})
          return {
            ...master,
            ...dongValues,
            TenGiai_VI,
            rowKey: `${master.PhongTraoID}-${index}`,
            _master: master
          }
        })
      })
    }
  },
  methods: {
    getDongLanguageLabel(language) {
      const labels = {
        VI: 'Tiếng Việt',
        EN: 'Tiếng Anh',
        ALL: 'Song ngữ / khác'
      }
      return labels[String(language || 'ALL').toUpperCase()] || 'Song ngữ / khác'
    },
    getDongRows(master) {
      if (Array.isArray(master?.DongNoiDung)) {
        return master.DongNoiDung.filter(row => row?.Enable !== false).sort((a, b) => Number(a.ThuTuDong || 0) - Number(b.ThuTuDong || 0))
      }
      // Fallback cho cache/API cũ chưa có DongJson; chỉ dùng để hiển thị, dữ liệu mới vẫn lưu ở bảng dòng động.
      return [
        { ThuTuDong: 1, NoiDung: master?.DanhHieu_VI || '' },
        { ThuTuDong: 2, NoiDung: master?.DanhHieu_EN || '' },
        { ThuTuDong: 3, NoiDung: master?.NamHoc || '' }
      ]
    },
    // Vuetify truyền isGroupOpen dưới dạng callback; gọi callback theo đúng group để icon và auto-open phản ánh trạng thái thật.
    isGroupOpenForItem(group, isGroupOpen) {
      return typeof isGroupOpen === 'function' ? isGroupOpen(group) : Boolean(isGroupOpen)
    },
    ensureSelectedGroupOpen(group, isOpen, toggleGroup) {
      const selectedName = this.vueData.selectedPhongTrao?.TenPhongTrao
      const isSelectedGroup = String(group?.value ?? '') === String(selectedName ?? '')
      if (!selectedName || !isSelectedGroup || this.isGroupOpenForItem(group, isOpen) || this.openingGroupName === selectedName) return false

      this.openingGroupName = selectedName
      this.$nextTick(() => {
        toggleGroup(group)
        this.openingGroupName = null
      })
      return false
    },
    isSelectedPrize(item) {
      const currentKey = item?.rowKey || item?.raw?.rowKey
      if (this.selectedPrizeKey) return this.selectedPrizeKey === currentKey
      // Khi trang tự chọn phong trào đầu tiên, phản chiếu lựa chọn đó ở dòng giải Nhất.
      const itemPtId = item?.PhongTraoID || item?.raw?.PhongTraoID
      return this.vueData.selectedPhongTrao?.PhongTraoID === itemPtId && String(currentKey || '').endsWith('-0')
    },
    getTemplateLabel(loaiMau) {
      const labels = {
        1: 'Mẫu 1 · Chỉ có lớp / Class only',
        2: 'Mẫu 2 · In sẵn tên học sinh + lớp',
        3: 'Mẫu 3 · GVCN chọn học sinh lớp chủ nhiệm',
        4: 'Mẫu tập thể · In theo lớp / Class'
      }
      return labels[Number(loaiMau)] || 'Chưa xác định mẫu'
    },
    async selectRow(_, row) {
      const item = row?.item?.raw || row?.item
      if (!item) return
      this.selectedPrizeKey = item.rowKey || null
      // API chi tiết chỉ nhận PhongTraoID; lưu thêm giải đang chọn để parent lọc lại sau mọi lần reload.
      this.vueData.selectedPrizeName = item.TenGiai_VI || ''
      if (!this.vueData.selectPhongTrao) return
      await this.vueData.selectPhongTrao(item._master || item)
    }
  }
	}
</script>
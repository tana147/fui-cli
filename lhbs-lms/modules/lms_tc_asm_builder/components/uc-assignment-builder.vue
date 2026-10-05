<template>
	<div class="assignment-builder">
        <!-- Mobile: Library Drawer (left) -->
        <v-navigation-drawer v-if="isMobile" v-model="isLibraryDrawerOpen" location="left" temporary width="300">
            <uc-assignment-component-library @add-component="addComponent" :in-drawer="true" @close="isLibraryDrawerOpen = false" style="height: 100%; overflow: auto" />
        </v-navigation-drawer>

        <!-- Mobile: Properties Drawer (right) -->
        <v-navigation-drawer v-if="isMobile" v-model="isPropertiesDrawerOpen" location="right" temporary width="400">
			<uc-assignment-properties :assignment="assignment" :groups="assignment.AssignmentConfig?.groups" :item="selectedItem" :open-import-type="groupImportType" :linked-hoc-lieu-i-d="linkedHocLieu?.HocLieuID || 0" @update:groups="updateGroups" @update:assignment="assignment = $event" :in-drawer="true" @close="isPropertiesDrawerOpen = false" />
        </v-navigation-drawer>

        <!-- Desktop: Properties navigation drawer -->
        <v-navigation-drawer v-if="!isMobile" v-model="isPropertiesDrawerOpen" location="right" temporary width="480" scrim @click:outside="isPropertiesDrawerOpen = false" class="assignment-properties-drawer">
			<uc-assignment-properties :assignment="assignment" :groups="assignment.AssignmentConfig?.groups" :item="selectedItem" :open-import-type="groupImportType" :linked-hoc-lieu-i-d="linkedHocLieu?.HocLieuID || 0" @update:groups="updateGroups" @update:assignment="assignment = $event" :in-drawer="true" @close="isPropertiesDrawerOpen = false" />
        </v-navigation-drawer>

        <!-- Mobile: Top Bar -->
        <div v-if="isMobile" class="mobile-top-bar d-flex align-center pa-2 ga-2">
            <v-btn icon variant="text" size="small" @click="isLibraryDrawerOpen = true">
                <v-icon>mdi-menu</v-icon>
                <v-tooltip activator="parent" location="bottom">{{ IsEngLish ? 'Add Question' : 'Thêm câu hỏi' }}</v-tooltip>
            </v-btn>
            <span class="text-body-2 flex-grow-1 text-truncate font-weight-medium">{{ assignment.Title || (IsEngLish ? 'Assignment' : 'Bài soạn') }}</span>
            <v-chip v-if="autoSaveStatus" size="x-small" :color="autoSaveStatus === 'saving' ? 'grey' : 'success'" variant="tonal">
                <v-icon v-if="autoSaveStatus === 'saving'" start size="12" class="mdi-spin">mdi-loading</v-icon>
                <v-icon v-else start size="12">mdi-check-circle-outline</v-icon>
                {{ autoSaveStatus === 'saving' ? (IsEngLish ? 'Saving...' : 'Đang lưu...') : (IsEngLish ? 'Saved' : 'Đã lưu') }}
            </v-chip>
            <v-btn icon variant="text" size="small" :disabled="!selectedItem" @click="isPropertiesDrawerOpen = true">
                <v-icon>mdi-tune-variant</v-icon>
                <v-tooltip activator="parent" location="bottom">{{ $t('message.Properties') }}</v-tooltip>
            </v-btn>
        </div>

        <!-- Desktop: 3-col layout -->
        <v-row v-if="!isMobile" class="ma-0" dense>
            <v-col cols="12" md="2">
                <div class="pa-3 py-2 d-flex align-center justify-space-between bg-grey-lighten-4">
                    <span class="text-caption font-weight-bold text-uppercase opacity-70">
                        {{ assignment.AssignmentType === 'INTEGRATED' ? (IsEngLish ? 'Library' : 'Thư viện') : (IsEngLish ? 'Question Library' : 'Thư viện câu hỏi') }}
                    </span>
                    <v-chip :color="assignment.AssignmentType === 'INTEGRATED' ? 'info' : 'primary'" variant="flat" size="x-small" class="font-weight-bold">
                        {{ assignment.AssignmentType === 'INTEGRATED' ? (IsEngLish ? 'EXTERNAL SOURCE' : 'NGUỒN NGOÀI') : 'LMS' }}
                    </v-chip>
                </div>
                <v-divider />
                <div v-if="assignment.AssignmentType !== 'INTEGRATED'">
                    <uc-assignment-component-library @add-component="addComponent" :hide-title="true" style="height: calc(-302px + 100dvh); overflow: auto" />
                </div>
                <div v-else class="pa-4 text-center">
                    <v-icon size="64" color="info" class="mb-4 opacity-20">mdi-link-variant</v-icon>
                    <v-alert type="info" variant="tonal" density="compact" :text="IsEngLish ? 'Integrated mode is enabled.' : 'Chế độ tích hợp đang bật.'" class="text-caption mb-4" />
                </div>

                <v-divider />

                <div class="pa-2">
                    <p class="text-subtitle-2 px-1 pt-2 mb-0">
                        {{ $t('message.Setting') }}
                    </p>
                    <div class="px-0">
                        <v-checkbox v-model="setting.IsBlockCopy_Paste" :label="IsEngLish ? 'Disable copy & paste' : 'Chặn copy paste'" density="compact" hide-details />
                    </div>
                    <v-divider class="my-2" />
                    <div class="mt-1">
                        <div class="text-display text-center mb-2">
                            {{ $t('message.TotalScore') }}
                            <v-chip variant="text" class="ps-1 pe-0 font-weight-medium" color="primary" size="medium">
                                {{ totalScoreAsm }}
                            </v-chip>
                        </div>
                        <v-row dense>
                            <v-col cols="12">
                                <v-btn @click="onRemarkQuestion" variant="outlined" color="amber" block size="small" :disabled="assignment.AssignmentType === 'INTEGRATED'">
                                    <v-icon start class="me-1">mdi-update</v-icon>{{ $t('message.SortNumber') }}
                                </v-btn>
                            </v-col>
                            <v-col cols="12">
                                <v-btn @click="isOpenDialogSource = true" variant="flat" color="primary" block size="small"> <v-icon start class="me-1">mdi-cog-outline</v-icon>{{ IsEngLish ? 'SETUP SOURCE' : 'Thiết lập nguồn' }} </v-btn>
                            </v-col>
                            <v-col v-if="!assignment.ExternalLink" cols="12">
                                <v-btn @click="onOpenPreview" variant="outlined" color="teal" block size="small">
                                    <v-icon start class="me-1">mdi-file-eye-outline</v-icon>{{ $t('message.Preview') }}
                                </v-btn>
                            </v-col>
                        </v-row>
                    </div>
                </div>
                <v-divider vertical />
            </v-col>

            <v-col cols="12" md="10" style="height: calc(100dvh); overflow: auto" class="d-flex flex-column">
                <!-- Top Bar (Clean) -->
                <div class="pa-4 pb-0 d-flex align-center justify-space-between">
                    <div class="d-flex align-center ga-2">
                        <span class="text-subtitle-1 font-weight-bold">
                            {{ assignment.Title || (IsEngLish ? 'Untitled' : 'Chưa đặt tiêu đề') }}
                        </span>
                    </div>

                    <div class="d-flex align-center ga-2 ms-auto">
                        <v-chip v-if="autoSaveStatus" size="x-small" :color="autoSaveStatus === 'saving' ? 'grey' : 'success'" variant="tonal">
                            <v-icon v-if="autoSaveStatus === 'saving'" start size="12" class="mdi-spin">mdi-loading</v-icon>
                            <v-icon v-else start size="12">mdi-check-circle-outline</v-icon>
                            {{ autoSaveStatus === 'saving' ? (IsEngLish ? 'Saving...' : 'Đang lưu...') : (IsEngLish ? 'Saved' : 'Đã lưu') }}
                        </v-chip>
                        <v-btn @click="handleSave(true)" variant="outlined" color="info" size="small">
                            <v-icon start>mdi-content-save-outline</v-icon>{{ $t('message.SaveAssignment') }}
                        </v-btn>
                        <v-btn v-if="!vueData.AssignToClassID" @click="openDialogAssignToStudent" variant="flat" color="success" size="small">
                            <v-icon start>mdi-clipboard-arrow-right-outline</v-icon>{{ $t('message.Assigned') }}
                        </v-btn>
                    </div>

                    <div v-if="assignment.AssignmentType === 'INTEGRATED'" class="d-flex align-center ga-2">
                        <v-chip size="small" variant="outlined" color="success" v-if="assignment.IntegrationSource && assignment.IntegrationSource !== 'LMS'">
                            {{ getSourceName(assignment.IntegrationSource) }}
                        </v-chip>
                        <v-chip size="small" variant="outlined" color="primary" v-if="!assignment.ExternalLink"> {{ totalScoreAsm }} {{ IsEngLish ? 'pts' : 'điểm' }} </v-chip>
                        <v-chip size="small" variant="outlined" color="primary" v-else> {{ IsEngLish ? 'Max score:' : 'Điểm tối đa:' }} {{ assignment.MaxScore }} </v-chip>
                    </div>
                </div>

                <v-divider class="my-4" />

                <div>
                    <uc-assignment-canvas
                        class="flex-grow-1 overflow-auto"
                        v-if="!assignment.ExternalLink"
                        :assignment="assignment"
                        :groups="assignment?.AssignmentConfig?.groups"
                        :can-import-from-hoc-lieu="hasHocLieuLink"
                        :selected-item="selectedItem"
                        @update:groups="updateGroups"
                        @update:selected-item="selectedItem = $event"
                        @open-group-import="handleGroupImport"
                        @remove-group="handleCanvasGroupRemove"
                        @remove-question="handleCanvasQuestionRemove"
                    />

                    <div v-else class="px-4 pb-4 h-100 d-flex flex-column">
                        <div v-if="!assignment.ExternalLink" class="pa-10 text-center text-medium-emphasis">
                            <v-icon size="64" color="primary" class="mb-4">mdi-link-variant</v-icon>
                            <h3 class="text-h6 mb-2">Bài tập tích hợp nguồn ngoài</h3>
                            <p>Vui lòng nhập link bài tập để xem trước nội dung tại đây.</p>
                        </div>
                        <div v-else class="flex-grow-1 d-flex flex-column">
                            <div class="d-flex align-center justify-space-between mb-2">
                                <div class="d-flex align-center ga-2">
                                    <v-icon color="success">mdi-eye-outline</v-icon>
                                    <span class="text-subtitle-2 font-weight-bold">Xem trước (Iframe)</span>
                                </div>
                                <v-btn size="x-small" variant="text" color="primary" @click="$forceUpdate()"> <v-icon start>mdi-refresh</v-icon>Tải lại preview </v-btn>
                            </div>
                            <v-card flat border class="flex-grow-1" style="min-height: 500px">
                                <iframe :src="assignment.ExternalLink" width="100%" height="100%" frameborder="0"></iframe>
                            </v-card>
                        </div>
                    </div>
                </div>
                <v-divider vertical />
            </v-col>
        </v-row>

        <!-- Mobile: Canvas -->
        <div v-if="isMobile" style="height: calc(100dvh - 96px); overflow: auto; padding-bottom: 64px">
            <div class="pa-2 d-flex align-center justify-space-between">
                <v-chip :color="assignment.ExternalLink ? 'info' : 'primary'" variant="tonal" size="small">
                    {{ assignment.ExternalLink ? (IsEngLish ? 'EXTERNAL SOURCE' : 'NGUỒN NGOÀI') : (IsEngLish ? 'LMS System' : 'Hệ thống LMS') }}
                </v-chip>
                <v-btn size="small" variant="outlined" color="primary" @click="isOpenDialogSource = true"> <v-icon start>mdi-cog-outline</v-icon>{{ IsEngLish ? 'SETUP SOURCE' : 'Thiết lập nguồn' }} </v-btn>
            </div>

            <div v-if="assignment.ExternalLink" class="pa-2 ga-2 d-flex flex-column">
                <div class="d-flex align-center justify-space-between mb-1">
                    <div class="d-flex align-center ga-1">
                        <v-icon size="small" color="success">mdi-eye-outline</v-icon>
                        <span class="text-caption font-weight-bold">{{ IsEngLish ? 'Preview (Iframe)' : 'Xem trước (Iframe)' }}</span>
                    </div>
                    <v-btn size="x-small" variant="text" color="primary" @click="$forceUpdate()"> <v-icon start>mdi-refresh</v-icon>Refresh </v-btn>
                </div>
                <v-card v-if="assignment.ExternalLink" flat border>
                    <iframe :src="assignment.ExternalLink" width="100%" height="100%" frameborder="0"></iframe>
                </v-card>
                <v-alert v-else type="info" variant="tonal" density="compact" text="Vui lòng thiết lập link bài tập để xem trước." />
            </div>
			<uc-assignment-canvas v-else :assignment="assignment" :groups="assignment?.AssignmentConfig?.groups" :selected-item="selectedItem" :can-import-from-hoc-lieu="hasHocLieuLink" @update:groups="updateGroups" @update:selected-item="selectedItem = $event" @open-group-import="handleGroupImport" @remove-group="handleCanvasGroupRemove" @remove-question="handleCanvasQuestionRemove" />
        </div>

        <!-- Mobile: Bottom Bar -->
        <div v-if="isMobile && (assignment.AssignmentConfig?.groups?.length > 0 || assignment.ExternalLink)" class="mobile-bottom-bar d-flex ga-2 pa-2">
            <v-btn variant="outlined" color="info" class="flex-grow-1" @click="handleSave(true)"> <v-icon start>mdi-content-save-outline</v-icon>{{ $t('message.SaveAssignment') }} </v-btn>
            <v-btn v-if="!vueData.AssignToClassID" variant="outlined" color="success" class="flex-grow-1" @click="openDialogAssignToStudent"> <v-icon start>mdi-clipboard-arrow-right-outline</v-icon>{{ $t('message.Assigned') }} </v-btn>
        </div>

        <uc-loading-page v-model="loadingPage.isLoading" v-model:text="loadingPage.text" />
        <!-- Dialog Import từ Content Hub: Soạn bài tập chỉ lấy câu hỏi/ngân hàng câu hỏi, ẩn hoàn toàn tab Tài liệu -->
        <uc-content-hub-import-dialog v-model="isContentHubImportOpen" :assignment="assignment"
            :questions-only="true" :allow-question-pool="true"
            :initial-import-mode="contentHubInitialMode"
            @import-question="importContentHubQuestion" @import-question-pool="importContentHubQuestionPool"
            @import-skill-matrix="importContentHubSkillMatrix"
            @import-document="importContentHubDocument" />
        <v-dialog v-model="isOpenDialogForAssignToStudent" max-width="800px">
            <v-card>
                <v-card-title class="bg-warning d-flex">
                    <span class="text-white">
                        {{ $t('message.AssignAssignment') }}
                    </span>
                    <v-spacer></v-spacer>
                    <v-btn variant="text" icon="mdi-close" color="white" @click="isOpenDialogForAssignToStudent = false"></v-btn>
                </v-card-title>
                <v-card-text>
                    <v-row dense class="mb-3">
                        <v-col cols="12">
                            <p class="text-subtitle-2 mb-3">
                                {{ $t('message.Time') }}
                            </p>
                            <div class="d-flex ga-3">
                                <v-text-field :model-value="formattedDate(deadlines?.date)" :label="$t('message.ExpirationDate')" readonly variant="outlined" @click="openDate(id)" />
                                <v-text-field :model-value="formattedTime(deadlines?.time)" :label="$t('message.ExpirationTime')" readonly variant="outlined" @click="openTime(id)" />
                            </div>
                            <!-- LimitAssigned là số lần làm tối đa, được cài ở bước giao bài. Mặc định là 1. -->
                            <v-number-input v-model="limitAssigned" class="mt-3" :label="IsEngLish ? 'Allowed attempts' : 'Số lần được làm bài'" :min="1" :step="1"
                                variant="outlined" density="compact" hide-details="auto" control-variant="stacked" />
                        </v-col>
                    </v-row>
                    <v-divider class="mb-1"></v-divider>
                    <div class="d-flex flex-column ga-1 my-1">
                        <span class="text-subtitle-2">{{ IsEngLish ? 'Teacher management permissions' : 'Phân quyền cho giáo viên quản lí' }}</span>
                        <v-select v-model="GiaoVienPermissionSelected" :label="IsEngLish ? 'Select teacher' : 'Chọn giáo viên'" :items="DSGiaoVien_Permission" item-title="HoTenGV" item-value="GiaoVienID" multiple chips>
                            <template #chip="{ item }">
                                <v-chip color="blue">{{ item.title }}</v-chip>
                            </template>
                        </v-select>
                        <!-- Quyền giáo viên độc lập với lớp: có thể lưu cùng lượt giao hoặc lưu riêng khi chưa chọn lớp/học sinh. -->
                        <span v-if="GiaoVienPermissionSelected.length > 0" class="text-caption text-medium-emphasis">
                            {{ hasAssignmentTarget ? (IsEngLish ? 'Selected teachers will be granted permissions in this assignment.' : 'Giáo viên đã chọn sẽ được phân quyền trong lượt giao bài này.') : (isPermissionOnlyUpdate ? (IsEngLish ? 'Can separately update teacher permissions for assigned assignments.' : 'Có thể cập nhật riêng phân quyền giáo viên cho bài đã giao.') : (IsEngLish ? 'The assignment has no class or student assigned; please select at least 1 class or 1 student to assign first.' : 'Bài chưa có lớp hoặc học sinh nhận; cần chọn ít nhất 1 lớp hoặc 1 học sinh để giao bài trước.')) }}
                        </span>
                    </div>
                    <v-divider class="mb-1"></v-divider>
                    <div class="d-flex">
                        <span class="text-subtitle-2 d-flex align-center">
                            {{ $t('message.ChooseClassToAssign') }}
                        </span>
                        <v-spacer></v-spacer>
                        <div class="d-flex ga-2" @click="selectedAllClass()">
                            <v-checkbox color="success" :indeterminate="isIndeterminate" v-model="isAllSelected" :label="$t('message.SelectAll')"> </v-checkbox>
                        </div>
                    </div>
                    <div class="d-flex ga-5 flex-wrap">
                        <v-tooltip v-for="item in filteredClassOptions" :key="item.LopID" :text="classDisabledReason(item.LopID)" location="top" :disabled="!classDisabledReason(item.LopID)">
                            <template #activator="{ props: tipProps }">
                                <div v-bind="tipProps" class="d-flex ga-1 justify-center align-center" :class="{ 'opacity-40': !!classDisabledReason(item.LopID) }">
                                    <v-checkbox v-model="selectedClass" :value="item.LopID" color="success" :disabled="!!classDisabledReason(item.LopID)" hide-details />
                                    <p>{{ item.TenLopDisplay || item.TenLop }}</p>
                                </div>
                            </template>
                        </v-tooltip>
                    </div>
                    <v-divider class="mb-2"></v-divider>
                    <div class="d-flex mb-2">
                        <p class="text-subtitle-2 d-flex align-center">
                            {{ $t('message.ChooseStudentToAssign') }}
                        </p>
                        <v-spacer></v-spacer>
                        <v-chip color="pink">{{ $t('message.Selected') }}: {{ DSHocSinhSelected.length }} {{ $t('message.Students') }}</v-chip>
                    </div>
                    <div class="d-flex">
                        <v-combobox v-model="DSHocSinhSelected" return-object :items="mappedItems" :label="$t('message.studentList')" density="compact" item-color="success" chips multiple variant="outlined">
                            <template #chip="{ item }">
                                <v-chip color="green">{{ item.title }}</v-chip>
                            </template>

                            <template #item="{ props, item }">
                                <v-list-item v-bind="props" :disabled="item.raw.disabled" @click.stop="item.raw.disabled && $event.stopPropagation()"> </v-list-item>
                            </template>
                        </v-combobox>
                    </div>
                </v-card-text>
                <v-divider></v-divider>
                <v-card-actions>
                    <v-spacer></v-spacer>
                    <v-btn variant="text" color="primary" @click="onAssignToStudentAndSave" :loading="isLoadDSHocSinh" :disabled="!canSubmitAssignment">
                        {{ isPermissionOnlyUpdate ? (IsEngLish ? 'Update permissions' : 'Cập nhật phân quyền') : $t('message.AssignAssignment') }}
                    </v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>
        <!-- Dialog chọn ngày (dùng 1 cái cho tất cả lớp) -->
        <v-dialog v-model="dateDialogVisible" max-width="350">
            <v-card>
                <v-date-picker v-model="deadlines.date" @update:model-value="dateDialogVisible = false" />
                <v-card-actions>
                    <v-spacer />
                    <v-btn variant="text" @click="dateDialogVisible = false">{{ $t('message.Cancel') }}</v-btn>
                    <v-btn color="primary" @click="dateDialogVisible = false">OK</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <!-- Dialog chọn giờ (dùng 1 cái cho tất cả lớp) -->
        <v-dialog v-model="timeDialogVisible" max-width="350">
            <v-card>
                <v-time-picker v-model="deadlines.time" format="24hr" @update:model-value="timeDialogVisible = false" />
                <v-card-actions>
                    <v-spacer />
                    <v-btn variant="text" @click="timeDialogVisible = false">{{ $t('message.Cancel') }}</v-btn>
                    <v-btn color="primary" @click="timeDialogVisible = false">OK</v-btn>
                </v-card-actions>
            </v-card>
        </v-dialog>

        <uc-dialog v-model="isOpenDialogSource" :title="IsEngLish ? 'Assignment source setup' : 'Thiết lập nguồn bài tập'" width="550" :doneText="IsEngLish ? 'FINISH' : 'Hoàn tất'" @onSubmit="onConfirmSource">
            <div class="pa-0">
                <p class="text-body-2 mb-4">{{ IsEngLish ? 'You can embed assignments from external sources (such as Azota, Etest, Quizizz, Google Forms...) by pasting the link here.' : 'Bạn có thể nhúng bài tập từ các nguồn bên ngoài (như Azota, Etest, Quizizz, Google Forms...) bằng cách dán đường dẫn (Link) vào đây.' }}</p>

                <div class="ga-4 d-flex flex-column">
                    <v-row dense>
                        <v-col cols="6">
                            <v-select
                                v-model="assignment.IntegrationSource"
                                :items="[
                                    { title: 'Azota', value: 'AZOTA' },
                                    { title: 'Etest (LHBS)', value: 'ETEST' },
                                    { title: IsEngLish ? 'Other' : 'Khác', value: 'OTHER' },
                                ]"
                                :label="IsEngLish ? 'Integrated source' : 'Nguồn tích hợp'"
                                variant="outlined"
                                density="compact"
                                hide-details
                            />
                        </v-col>
                        <v-col cols="6">
                            <v-text-field v-model="assignment.MaxScore" :label="IsEngLish ? 'Max score' : 'Thang điểm tối đa'" variant="outlined" density="compact" hide-details type="number" prepend-inner-icon="mdi-star-outline" />
                        </v-col>
                        <v-col cols="12" class="mt-2">
                            <v-text-field
                                v-model="assignment.ExternalLink"
                                :label="IsEngLish ? 'Assignment link from external source' : 'Đường dẫn (Link) bài tập từ nguồn ngoài'"
                                variant="outlined"
                                density="compact"
                                hide-details
                                placeholder="https://azota.vn/..."
                                clearable
                                prepend-inner-icon="mdi-link-variant"
                            />
                            <div class="text-caption text-medium-emphasis mt-1">{{ IsEngLish ? 'Paste link from Azota, Etest or other sources here. If link is provided, the system will switch to "External source" mode.' : 'Dán link từ Azota, Etest hoặc nguồn khác vào đây. Nếu có link, hệ thống sẽ chuyển sang chế độ "Nguồn ngoài".' }}</div>
                        </v-col>
                    </v-row>
                </div>

                <v-divider class="my-4" />
                <div class="text-caption text-medium-emphasis">
                    <v-icon size="small" class="me-1">mdi-information-outline</v-icon>
                    {{ IsEngLish ? 'To create assignment directly on LMS, please leave the "Link" field empty.' : 'Để soạn bài tập trực tiếp trên LMS, vui lòng để trống ô "Đường dẫn".' }}
                    <!-- <div class="mt-1">Hoặc chuyển nguồn tích hợp về LMS.</div> -->
                </div>
            </div>
        </uc-dialog>
    </div>
</template>

<script>
	export default {
		name: 'uc-assignment-builder',
    inject: ['confirmRef', 'iframeRef', 'snackbarRef'],
    props: {
        initialAssignment: undefined,
        isEditMode: Boolean,
        onSave: { type: Function, default: () => {} },
        onAutoSave: { type: Function, default: () => {} },
    },
    data() {
        const toggle = JSON.parse(localStorage.getItem('IsLanguage')) ?? false
        this.$i18n.locale = toggle ? 'en' : 'vi'
        return {
            SelectedClasses: null,
            timeDialogVisible: false,
            dateDialogVisible: false,
            isOpenDialogForAssignToStudent: false,
            isOpenDialogSource: false,
            setting: {
                IsBlockCopy_Paste: false,
            },
            vueData,
            loadingPage: {
                isLoading: false,
                text: 'Đang tải dữ liệu...',
            },
            assignment: {
                Title: '',
                Instructions: '',
                // ExternalLink: '',
                AssignmentConfig: { groups: [] },
            },
            selectedItem: null,
            groupImportType: '',
            isContentHubImportOpen: false,
            contentHubImportGroupIndex: null,
            contentHubInitialMode: 'STANDARD',
            fileAudio: null,
            classOptions: [],
            hasExistingAssignmentTarget: false,
            isOpenSheetAssignToClass: false,
            deadlines: {
                date: null,
                time: null,
            },
            limitAssigned: 1,
            selectedClass: [],
            classAssigned: [],
            isLoadDSHocSinh: false,
            DSHocSinhByLopID: [],
            DSHocSinhSelected: [],
            DSGiaoVien_Permission: [],
            GiaoVienPermissionSelected: [],
            autoSaveStatus: null,
            lastSavedAt: null,
            relativeTimeNow: null,
            isLibraryDrawerOpen: false,
            isPropertiesDrawerOpen: false,
            isSaving: false,
            isDeletingElement: false,
            _skipNextAutoSave: false,
            autoSaveTimer: null,
            linkedHocLieu: null,
            relativeTimeTimer: null,
        }
    },
    mounted() {
        console.log('vueData.NienKhoaItem', vueData.NienKhoaItem)
        fetchPromise('/lms/EL_Teacher_GetLop_GiaoBai', {
                AssignmentID: vueData.assignment.AssignmentID,
                MonHocID: vueData.assignment.MonHocID,
                ResourceType: 'ASSIGNMENT',
            }, { cache: false })
            .then(res => this.loadAssignableClasses(res, vueData.AssignmentID))
            .catch(error => this.showSnackbar(error?.Message || error?.message || 'Không thể tải danh sách lớp.', 'error'))
    },
    beforeUnmount() {
        this.setIframeCloseHidden(false)
        clearTimeout(this.autoSaveTimer)
        clearInterval(this.relativeTimeTimer)
    },
    computed: {
        IsEngLish() {
            if (this.$i18n?.locale === 'en') return true
            try {
                const isLang = JSON.parse(localStorage.getItem('IsLanguage'))
                return isLang === true || isLang === 'true'
            } catch (e) {
                return localStorage.getItem('IsLanguage') === 'true'
            }
        },
        filteredClassOptions() {
            return (this.classOptions || []).filter(item => {
                const name = String(item?.TenLopDisplay || item?.TenLop || '').trim();
                const id = String(item?.LopID || '');
                if (vueData.assignment?.MonHocID === 102) {
                    return name.includes('TH') || id.startsWith('N');
                }
                return true;
            });
        },
        isMobile() {
            return this.$vuetify.display.smAndDown
        },
        isMatrixAssignment() {
            const groups = this.assignment?.AssignmentConfig?.groups || []
            return groups.some(g =>
                g?.questionSource?.sourceKind === 'QUESTION_BANK_SKILL_MATRIX' ||
                g?.questionSource?.matrixMode === true ||
                g?.questionSelection?.matrixMode === true
            )
        },
		hasHocLieuLink() { return !!this.linkedHocLieu?.HocLieuID },
        lastSavedRelative() {
            if (!this.lastSavedAt) return ''
            const now = this.relativeTimeNow || Date.now()
            const diff = Math.floor((now - this.lastSavedAt) / 1000)
            if (diff < 10) return 'vừa lưu'
            if (diff < 60) return `${diff} giây trước`
            return `${Math.floor(diff / 60)} phút trước`
        },
        isIndeterminate: function () {
            return this.selectedClass.length != 0 && this.selectedClass.length !== this.filteredClassOptions.length
        },
        isAllSelected: function () {
            return this.selectedClass.length != 0 && this.selectedClass.length == this.filteredClassOptions.length
        },
        hasAssignmentTarget() {
            return this.selectedClass.length > 0 || this.DSHocSinhSelected.length > 0
        },
        isPermissionOnlyUpdate() {
            return !this.hasAssignmentTarget && this.GiaoVienPermissionSelected.length > 0
        },
        canSubmitAssignment() {
            return this.hasAssignmentTarget || this.GiaoVienPermissionSelected.length > 0
        },
        totalScoreAsm() {
            const isIntegration = this.assignment.AssignmentType === 'INTEGRATED' || (this.assignment.IntegrationSource && this.assignment.IntegrationSource !== 'LMS')
            if (isIntegration || this.assignment.ExternalLink) {
                return this.formatNumber(this.assignment.MaxScore || 0, 2)
            }
            if (!this.assignment?.AssignmentConfig?.groups) return this.formatNumber(0)

            let total = 0

            // Group random chỉ đóng góp điểm của số câu được lấy mỗi lượt,
            // còn group mặc định vẫn cộng toàn bộ câu như flow cũ.
            this.assignment.AssignmentConfig.groups.forEach((group) => {
                total += this.getEffectiveGroupScore(group)
            })

            return this.formatNumber(total, 2)
        },
        mappedItems: function () {
            return this.DSHocSinhByLopID
                .filter((item) => !item.disabled && !this.selectedClass.includes(item.LopID))
                .map((item) => {
                return { title: item.TenLop + ` - ` + item.Ho + ' ' + item.Ten, value: item.HocSinhID, ...item }
            })
        },
        DSHocSinhAssigned: function () {
            return this.DSHocSinhByLopID.filter((item) => item.disabled)
        },
    },
    methods: {
		showSnackbar(message, color = 'info') {
			this.snackbarRef?.value?.showSnackbar?.({ message, color })
		},
		getCurrentSchoolYear() {
			return Number(vueData.assignment?.NienKhoa ?? vueData.NienKhoa ?? 0)
		},
		getCurrentGradeId() {
			return Number(vueData.assignment?.KhoiID ?? 0)
		},
		getCurrentTeacherId() {
			return vueData.GiaoVienID_Selected || vueData.assignment?.GiaoVienID || vueData.user?.UserID
		},
		async getAssignedClassNames(assignmentID, resourceType) {
			try {
				const response = await fetchPromise('/lms/EL_Teacher_GetAssignmentStatusByClass', {
					AssignmentID: assignmentID,
					ResourceType: resourceType
				}, { cache: false })
				const rows = (Array.isArray(response) ? response : []).flat(Infinity).filter(row => row?.TenLop)
				return new Set(rows.map(row => String(row.TenLop).trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN')))
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || error?.response?.data?.Message || 'Không thể kiểm tra trạng thái giao bài. Vui lòng thử lại.', 'error')
				return new Set()
			}
		},
		isClassInCurrentGrade(row, gradeId) {
			if (!gradeId) return true
			if (row?.KhoiID != null) return Number(row.KhoiID) === gradeId
			const gradeFromName = String(row?.TenLop ?? '').trim().match(/^\d+/)?.[0]
			return gradeFromName ? Number(gradeFromName) === gradeId : false
		},
		async getTeacherAssignedClasses(teacherId) {
			try {
				const response = await fetchPromise('/lms/GiaoVienLop_Get_By_GiaoVienID', {
					GiaoVienID: teacherId || this.getCurrentTeacherId()
				}, { cache: false })
				const rows = (Array.isArray(response) ? response : []).flat(Infinity)
				const schoolYear = this.getCurrentSchoolYear()
				const gradeId = this.getCurrentGradeId()
				return rows.filter(row => (row?.Enable == null || [true, 1, '1'].includes(row.Enable))
					&& (!schoolYear || row?.NienKhoa == null || Number(row.NienKhoa) === schoolYear)
					&& this.isClassInCurrentGrade(row, gradeId))
			} catch (error) {
				this.showSnackbar(error?.Message || error?.message || 'Không thể tải lớp giáo viên phụ trách.', 'error')
				return []
			}
		},
		normalizeClassOptions(items) {
			const rows = (Array.isArray(items) ? items : []).filter(item => item?.LopID != null && String(item?.TenLop ?? '').trim())
			const seenIds = new Set()
			const uniqueRows = rows.filter(item => {
				const id = String(item.LopID)
				if (seenIds.has(id)) return false
				seenIds.add(id)
				return true
			})
			return uniqueRows.map(item => {
				const name = String(item.TenLop).trim().replace(/\s+/g, ' ')
				return {
					...item,
					TenLopDisplay: name
				}
			})
		},
		async loadAssignableClasses(items, assignmentID) {
			const sourceItems = Array.isArray(items) ? items.flat() : []
			const assignedClassNames = await this.getAssignedClassNames(assignmentID, 'ASSIGNMENT')
			// Quyền giáo viên chỉ được cập nhật riêng cho bài đã có ít nhất một lớp/học sinh nhận.
			// Nếu bài hoàn toàn mới chưa có người nhận, vẫn phải yêu cầu chọn đối tượng giao bài.
			this.hasExistingAssignmentTarget = assignedClassNames.size > 0
			const availableSourceItems = sourceItems.filter(item => !assignedClassNames.has(
				String(item?.TenLop ?? '').trim().replace(/\s+/g, ' ').toLocaleLowerCase('vi-VN')
			))
			const candidates = this.normalizeClassOptions(availableSourceItems)
			const checked = await Promise.all(candidates.map(async item => {
				try {
					const response = await fetchPromise('/lms/HocSinhLop_GetByLopIDList', {
						DSLopID: JSON.stringify([item.LopID]),
						AssignmentID: assignmentID || 0,
						NienKhoa: Number(vueData.assignment?.NienKhoa ?? vueData.NienKhoa ?? 0),
					}, { cache: false })
					const students = (Array.isArray(response) ? response : []).flat(Infinity)
					return { item, hasActiveStudents: students.some(student => [true, 1, '1'].includes(student?.Enable)) }
				} catch { return { item, hasActiveStudents: false } }
			}))
			this.classOptions = checked.filter(row => row.hasActiveStudents).map(row => row.item)
		},
		async loadHocLieuMapping(assignmentID) {
			if (!assignmentID) { this.linkedHocLieu = null; return }
			try {
				const response = await fetchPromise('lms/EL_HocLieuResource_Get', { ResourceType: 'ASSIGNMENT', ResourceID: assignmentID }, { cache: false })
				const rows = response ?? []
				this.linkedHocLieu = Array.isArray(rows?.[0]) ? rows[0][0] : (Array.isArray(rows) ? rows[0] : rows)
			} catch (error) { this.showSnackbar(error?.Message || error?.message || 'Không thể tải liên kết học liệu.', 'error') }
		},
        setIframeCloseHidden(hidden) {
            const message = { type: hidden ? 'iframeRef_hideClose' : 'iframeRef_showClose' }
            if (window !== window.top) window.parent.postMessage(message, '*')
            else if (this.iframeRef?.value?.setCloseVisible) this.iframeRef.value.setCloseVisible(!hidden)
        },
        onConfirmSource() {
            const maxScore = Number(this.assignment.MaxScore)
            if (!this.assignment.MaxScore || isNaN(maxScore) || maxScore <= 0) {
                this.showSnackbar('Vui lòng nhập thang điểm tối đa hợp lệ.', 'warning')
                return
            }

            const link = (this.assignment.ExternalLink || '').trim()
            if (!link) {
                this.showSnackbar('Vui lòng nhập đường dẫn link bài tập.', 'warning')
                return
            }

            if (this.assignment.IntegrationSource === 'AZOTA' && !link.includes('azota.vn')) {
                this.showSnackbar('Đường dẫn không hợp lệ. Vui lòng nhập link từ Azota (azota.vn).', 'warning')
                return
            }
            if (this.assignment.IntegrationSource === 'ETEST' && !link.includes('etest.lhbs.vn')) {
                this.showSnackbar('Đường dẫn không hợp lệ. Vui lòng nhập link từ Etest (etest.lhbs.vn).', 'warning')
                return
            }

            this.isOpenDialogSource = false
        },
        getSourceName(code) {
            const sources = {
                AZOTA: 'Azota',
                ETEST: 'Etest (LHBS)',
                OTHER: 'Khác',
                LMS: 'LMS',
            }
            return sources[code] || code
        },
        scheduleAutoSave() {
            const hasId = Number(this.assignment?.AssignmentID || vueData.AssignmentID || 0) > 0
            if (!this.isEditMode && !hasId) return
            // Skip auto-save triggered by initial data load
            if (this._skipNextAutoSave) {
                this._skipNextAutoSave = false
                return
            }
            clearTimeout(this.autoSaveTimer)
            this.autoSaveTimer = setTimeout(async () => {
                // Skip if a manual save is already in progress
                if (this.isSaving) return
                this.isSaving = true
                try {
                    const groups = this.assignment.AssignmentConfig?.groups || []
                    const link = this.assignment.ExternalLink?.trim() || ''

                    // Nếu có link, kiểm tra domain hợp lệ mới auto-save
                    if (link !== '') {
                        if (this.assignment.IntegrationSource === 'AZOTA' && !link.includes('azota.vn')) return
                        if (this.assignment.IntegrationSource === 'ETEST' && !link.includes('etest.lhbs.vn')) return
                    }

                    const isIntegration = this.assignment.IntegrationSource && this.assignment.IntegrationSource !== 'LMS'
                    const isNotFullQuiz = (isIntegration || this.assignment.ExternalLink) ? true : vueData.isCheckAllGroupFullQuiz(groups)
                    const payload = {
                        assignment: this.assignment,
                        isPublishing: false,
                        Is_Full_Quiz: !isNotFullQuiz,
                        setting: this.setting,
                    }
                    this.autoSaveStatus = 'saving'
                    await this.onAutoSave(payload)
                    this.lastSavedAt = Date.now()
                    this.relativeTimeNow = Date.now()
                    this.autoSaveStatus = 'saved'
                    clearInterval(this.relativeTimeTimer)
                    this.relativeTimeTimer = setInterval(() => {
                        this.relativeTimeNow = Date.now()
                    }, 10000)
                } finally {
                    this.isSaving = false
                }
            }, 2000)
        },
        formatNumber(value, decimals = 2) {
            const num = Number(value)

            if (isNaN(num)) return (0).toFixed(decimals)

            return num.toFixed(decimals)
        },
        onRemarkQuestion() {
            let number = 0
            this.assignment?.AssignmentConfig?.groups.forEach((group) => {
                group.questions = group.questions.map((x) => {
                    number++ // tăng lần lượt 1, 2, 3, 4...
                    x.ordinalNumber = number
                    return x
                })
            })
        },
        handleGroupImport({ groupIndex, source }) {
            if (source === 'contentHub') {
                this.contentHubImportGroupIndex = groupIndex
                this.contentHubInitialMode = 'STANDARD'
                this.isContentHubImportOpen = true
                return
            }
            this.selectedItem = { type: 'group', groupIndex, qIndex: null }
            this.isPropertiesDrawerOpen = true
            this.groupImportType = ''
            this.$nextTick(() => { this.groupImportType = source })
        },
        getDefaultRandomQuestionCount(poolSize) {
            const size = Math.max(Number(poolSize) || 0, 0)
            return size ? Math.min(size, Math.max(1, Math.ceil(size * 0.75))) : 1
        },
        // Group RANDOM tiêu chuẩn bốc trên toàn bộ câu đang thuộc group.
        // questionSource.questionIds chỉ là metadata nguồn (và được dùng riêng cho ma trận),
        // không được thu hẹp kho random của group tiêu chuẩn.
        getRandomPoolSize(group) {
            return Array.isArray(group?.questions) ? group.questions.length : 0
        },
        // Điểm tối đa phải tính theo số câu thực tế được lấy mỗi lượt.
        // Cách tính theo tỉ lệ giữ đúng tổng điểm nếu các câu trong group có điểm khác nhau.
        getEffectiveGroupScore(group) {
            const questions = Array.isArray(group?.questions) ? group.questions : []
            const poolScore = questions.reduce((sum, question) => {
                const points = Number(question?.points ?? 0)
                return sum + (Number.isFinite(points) && points > 0 ? points : 0)
            }, 0)
            if (group?.questionSelection?.mode !== 'RANDOM') return poolScore

            const requested = Math.floor(Number(group.questionSelection?.questionsPerAttempt))
            const count = Math.min(
                Math.max(Number.isFinite(requested) ? requested : 0, 0),
                questions.length
            )
            return questions.length ? poolScore * (count / questions.length) : 0
        },
        importContentHubQuestion(question) {
            const groupIndex = Number(this.contentHubImportGroupIndex)
            const groups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const group = groups[groupIndex]
            if (!group) return
            const totalQuestions = groups.reduce((sum, item) => sum + (item.questions?.length || 0), 0)
            group.questions = [...(group.questions || []), { ...question, ordinalNumber: totalQuestions + 1 }]

            // Import thủ công vẫn chỉ thêm câu đã chọn. Metadata nguồn được giữ để lọc/ma trận;
            // random tiêu chuẩn vẫn bốc trên toàn bộ câu hiện có trong group.
            const sourceFileName = question?.sourceTracking?.sourceFileName
            const sourceQuestions = group.questions || []
            const sourceIds = sourceQuestions.map(item => item?.sourceTracking?.questionId)
            const isSingleSourcePool = Boolean(sourceFileName)
                && sourceQuestions.length > 0
                && sourceQuestions.every(item => item?.sourceTracking?.sourceFileName === sourceFileName
                    && item?.sourceTracking?.questionId !== undefined && item?.sourceTracking?.questionId !== null)
            const currentSourceName = group.questionSource?.sourceFileName
            if (isSingleSourcePool && (!currentSourceName || currentSourceName === sourceFileName)) {
                group.questionSource = {
                    sourceType: 'CONTENT_HUB',
                    sourceKind: 'QUESTION_BANK_FILE',
                    groupId: group.questionSource?.groupId || question?.sourceTracking?.groupId,
                    sourceFileName,
                    questionIds: [...new Set(sourceIds.map(String))],
                    poolSize: sourceIds.length,
                    importedAt: group.questionSource?.importedAt || new Date().toISOString(),
                }
            }
            this.updateGroups(groups)
        },
        importContentHubQuestionPool({ questions = [], source = null } = {}) {
            const groupIndex = Number(this.contentHubImportGroupIndex)
            const groups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const group = groups[groupIndex]
            if (!group || !Array.isArray(questions) || !questions.length || !source) return

            // Snapshot câu import vẫn được lưu để truy vết nguồn và phục vụ flow ma trận.
            // Với group RANDOM tiêu chuẩn, runtime bốc trong toàn bộ group.questions.
            const getSourceQuestionId = question => question?.sourceTracking?.questionId ?? question?.id
            const existingIds = new Set((group.questions || []).map(getSourceQuestionId).filter(id => id !== undefined && id !== null).map(String))
            const importedQuestions = questions.filter(question => {
                const id = getSourceQuestionId(question)
                return id !== undefined && id !== null && !existingIds.has(String(id))
            })
            const totalQuestions = groups.reduce((sum, item) => sum + (item.questions?.length || 0), 0)
            group.questions = [...(group.questions || []), ...importedQuestions.map((question, index) => ({
                ...question,
                ordinalNumber: totalQuestions + index + 1,
            }))]
            group.questionSource = {
                ...source,
                questionIds: questions.map(getSourceQuestionId).filter(id => id !== undefined && id !== null).map(String),
                poolSize: questions.length,
            }
            // Sau khi gộp vào group, lấy lại kích thước toàn bộ group để không lệch khi danh sách import có câu trùng
            // hoặc group đã có sẵn câu thuộc cùng nguồn.
            const groupPoolSize = this.getRandomPoolSize(group)
            group.questionSelection = {
                ...(group.questionSelection || {}),
                mode: 'RANDOM',
                defaultRandomCountApplied: true,
                questionsPerAttempt: Math.min(
                    Math.max(
                        group.questionSelection?.defaultRandomCountApplied
                            ? (Number(group.questionSelection?.questionsPerAttempt) || this.getDefaultRandomQuestionCount(groupPoolSize))
                            : this.getDefaultRandomQuestionCount(groupPoolSize),
                        1
                    ),
                    groupPoolSize || 1
                ),
            }
            this.updateGroups(groups)
        },
        importContentHubSkillMatrix(matrixConfigs = []) {
            const groupIndex = Number(this.contentHubImportGroupIndex)
            const groups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const group = groups[groupIndex]
            if (!group || !Array.isArray(matrixConfigs) || !matrixConfigs.length) return

            // Ma trận được lưu theo từng mức độ và từng nhóm nguồn để runtime có thể bốc đúng quota,
            // còn group.questions vẫn giữ snapshot phẳng để giao diện/chấm điểm dùng chung contract cũ.
            const getSourceQuestionId = question => question?.sourceTracking?.questionId ?? question?.id
            const existingIds = new Set((group.questions || []).map(getSourceQuestionId).filter(id => id !== undefined && id !== null).map(String))
            const importedQuestions = matrixConfigs
                .flatMap(config => config.questions || [])
                .filter(question => {
                    const id = getSourceQuestionId(question)
                    return id !== undefined && id !== null && !existingIds.has(String(id))
                })
            if (!importedQuestions.length) return

            const totalQuestions = groups.reduce((sum, item) => sum + (item.questions?.length || 0), 0)
            group.questions = [...(group.questions || []), ...importedQuestions.map((question, index) => ({
                ...question,
                ordinalNumber: totalQuestions + index + 1,
            }))]

            const matrixQuestionIds = matrixConfigs
                .flatMap(config => config.questions || [])
                .map(getSourceQuestionId)
                .filter(id => id !== undefined && id !== null)
                .map(String)
            const normalizedMatrixConfigs = matrixConfigs.map(config => ({
                skillId: config.skillId,
                skillName: config.skillName,
                skillGroup: config.skillGroup,
                randomCount: Number(config.randomCount) || 0,
                availableCount: Number(config.availableCount) || 0,
                questionIds: (config.questions || []).map(getSourceQuestionId)
                    .filter(id => id !== undefined && id !== null).map(String),
                sources: (config.sources || []).map(source => ({
                    sourceId: source.sourceId,
                    groupId: source.groupId,
                    groupTitle: source.groupTitle,
                    randomCount: Number(source.randomCount) || 0,
                    availableCount: Number(source.availableCount) || 0,
                    questionIds: (source.questionIds || []).map(String),
                })),
            }))
            group.questionSource = {
                sourceType: 'CONTENT_HUB',
                sourceKind: 'QUESTION_BANK_SKILL_MATRIX',
                matrixMode: true,
                groupIds: [...new Set(normalizedMatrixConfigs.flatMap(config => config.sources.map(source => source.groupId)).filter(Boolean))],
                questionIds: [...new Set(matrixQuestionIds)],
                matrixConfigs: normalizedMatrixConfigs,
                poolSize: matrixQuestionIds.length,
                importedAt: new Date().toISOString(),
            }
            group.questionSelection = {
                ...(group.questionSelection || {}),
                mode: 'RANDOM',
                matrixMode: true,
                defaultRandomCountApplied: true,
                questionsPerAttempt: normalizedMatrixConfigs.reduce((sum, config) => sum + config.randomCount, 0),
            }
            this.updateGroups(groups)
        },
        importContentHubDocument(document) {
            const groupIndex = Number(this.contentHubImportGroupIndex)
            const groups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const group = groups[groupIndex]
            if (!group || !document?.source) return
            // Chuẩn hóa dấu vết ngay tại cửa ngõ import để thao tác xóa element sau này
            // biết đây là tài liệu dùng chung, kể cả khi API không trả sourceTracking.
            const importedDocument = {
                ...document,
                sourceTracking: {
                    ...(document.sourceTracking || {}),
                    sourceType: document.sourceTracking?.sourceType || document.sourceType || 'CONTENT_HUB',
                    sourceKind: document.sourceTracking?.sourceKind || 'DOCUMENT',
                    importedAt: document.sourceTracking?.importedAt || new Date().toISOString(),
                },
            }
            // AssignmentConfig chưa có block tài liệu riêng; media cấp nhóm giữ được file/link mà không đổi contract DB. 
            group.media = group.media || {
                type: 'YOUTUBE',
                sourceYT: { id: '', source: '', name: '' },
                sourceRecord: { id: '', source: '', name: '' },
                sourceFiles: { file: [], image: [] },
            }
            group.media.sourceFiles = group.media.sourceFiles || { file: [], image: [] }
            const type = `${importedDocument.contentType || ''} ${importedDocument.name || ''} ${importedDocument.source || ''}`.toLowerCase()
            if (/image|\.png|\.jpe?g|\.gif|\.webp|\.svg/.test(type)) {
                group.media.sourceFiles.image = [...(group.media.sourceFiles.image || []), importedDocument]
            } else if (/youtube|youtu\.be/.test(type)) {
                group.media.sourceYT = { id: importedDocument.id || '', name: importedDocument.name, source: importedDocument.source, sourceTracking: importedDocument.sourceTracking }
            } else if (/audio|\.mp3|\.wav|\.aac|\.m4a|\.ogg/.test(type)) {
                group.media.sourceRecord = { id: importedDocument.id || '', name: importedDocument.name, source: importedDocument.source, sourceTracking: importedDocument.sourceTracking }
            } else {
                group.media.sourceFiles.file = [...(group.media.sourceFiles.file || []), importedDocument]
            }
            this.updateGroups(groups)
        },
        async onOpenPreview() {
            const groups = this.assignment.AssignmentConfig.groups
            const { message, isNotChoose } = vueData.isCheckGroupHasAnswerQuestionNotChoose(groups)
            if (isNotChoose) {
                this.showSnackbar(message + ' chưa có đáp án. Vui lòng kiểm tra lại.', 'warning')
                return
            }
            await this.handleSave(true)
            openWindow({
                title: 'Xem trước bài soạn',
                url: `/lms-tc-asm-preview?AssignmentID=${vueData.AssignmentID || 0}&AssignToClassID=${vueData.AssignToClassID || 0}`,
            })
        },
        selectedAllClass() {
            if (this.isAllSelected) {
                this.selectedClass = []
            } else {
                this.selectedClass = this.filteredClassOptions.map((i) => i.LopID)
            }
        },
        handleClickClass(item) {
            if (!this.selectedClass.includes(item.LopID)) {
                this.selectedClass.push(item.LopID)
            } else {
                let indexOfLopID = this.selectedClass.indexOf(item.LopID)
                this.selectedClass.splice(indexOfLopID, 1)
            }
        },
        getQuestionContentText(question) {
            const config = question?.config || {}
            const value = question?.questionText || question?.QuestionText || config.questionText || config.prompt || question?.prompt || ''
            if (typeof value === 'string' || typeof value === 'number') return String(value)
            return value?.html || value?.content || value?.text || value?.value || ''
        },
        getMissingQuestionContent(groups) {
            const missingQuestions = []
            ;(groups || []).forEach(group => {
                ;(group?.questions || []).forEach(question => {
                    const text = String(this.getQuestionContentText(question) || '')
                        .replace(/<[^>]*>/g, ' ')
                        .replace(/&nbsp;/gi, ' ')
                        .replace(/\s+/g, ' ')
                        .trim()
                    if (!text) missingQuestions.push(question)
                })
            })
            const labels = missingQuestions.map(question => question?.ordinalNumber ? `Câu ${question.ordinalNumber}` : 'Câu hỏi')
            return {
                isMissing: missingQuestions.length > 0,
                message: [...new Set(labels)].join(', '),
            }
        },
        validateQuestionContentBeforeAssign(groups) {
            const { message, isMissing } = this.getMissingQuestionContent(groups)
            if (!isMissing) return true

            // Chặn trước khi mở dialog giao bài để giáo viên quay lại nhập nội dung câu hỏi còn thiếu.
            this.showSnackbar(`${message} chưa có nội dung câu hỏi. Vui lòng nhập trước khi giao bài.`, 'warning')
            return false
        },
        openSheetAssignToClass() {
            const groups = this.assignment.AssignmentConfig.groups
            if (!this.validateQuestionContentBeforeAssign(groups)) return
            const { message, isNotChoose } = vueData.isCheckGroupHasAnswerQuestionNotChoose(groups)
            if (isNotChoose) {
                this.showSnackbar(message + ' chưa có đáp án. Vui lòng kiểm tra lại.', 'warning')
                return
            }
            this.isOpenSheetAssignToClass = true
        },
        openDialogAssignToStudent() {
            const groups = this.assignment.AssignmentConfig.groups
            if (!this.validateQuestionContentBeforeAssign(groups)) return
            const { message, isNotChoose } = vueData.isCheckGroupHasAnswerQuestionNotChoose(groups)
            if (isNotChoose) {
                this.showSnackbar(message + ' chưa có đáp án. Vui lòng kiểm tra lại.', 'warning')
                return
            }
            this.isOpenDialogForAssignToStudent = true
        },
        async onAssignToClassAndSave() {
            if (this.deadlines?.date == null || this.deadlines?.time == null) {
                this.showSnackbar('Vui lòng nhập ngày giờ', 'error')
                return
            }
            if (this.selectedClass.length == 0) {
                this.showSnackbar('Vui lòng chọn ít nhất 1 lớp để giao bài!', 'error')
                return
            }
            const d = { date: this.deadlines?.date, time: this.deadlines?.time }
            const due = this.getDue(d)
            // truyền true => isPushlish = true
            const groups = this.assignment.AssignmentConfig.groups
            const isIntegration = this.assignment.IntegrationSource && this.assignment.IntegrationSource !== 'LMS'
            const isNotFullQuiz = (isIntegration || this.assignment.ExternalLink) ? true : vueData.isCheckAllGroupFullQuiz(groups)
            
            const success = await this.handleSave(true)
            if (!success) return

            await new Promise((resolve) => setTimeout(resolve, 1000)) // thực sự delay 2s

            this.showSnackbar('Lưu bài và giao bài thành công!', 'success')
            this.isOpenDialogForAssignToStudent = false
            // Quay về trang dashboard
            if (window !== window.top) {
                window.parent.postMessage({ type: 'iframeRef_closeWindow' }, '*')
            } else {
                window.open('/lms-teacher-dashboard', '_parent')
            }
        },
        async onAssignToStudentAndSave() {
            const hasTeacherPermission = this.GiaoVienPermissionSelected.length > 0
            if (!this.hasAssignmentTarget && (!hasTeacherPermission || !this.hasExistingAssignmentTarget)) {
                this.showSnackbar('Vui lòng chọn ít nhất 1 lớp hoặc 1 học sinh để giao bài. Phân quyền giáo viên chỉ áp dụng riêng cho bài đã được giao trước đó.', 'error')
                return
            }
            // Cập nhật quyền không tạo lượt giao mới nên không cần nhập lại hạn nộp.
            if (!this.isPermissionOnlyUpdate && (this.deadlines?.date == null || this.deadlines?.time == null)) {
                this.showSnackbar(this.IsEngLish ? 'Please enter date and time.' : 'Vui lòng nhập ngày giờ', 'error')
                return
            }
            if (!this.isPermissionOnlyUpdate && (!Number.isInteger(Number(this.limitAssigned)) || Number(this.limitAssigned) < 1)) {
                this.showSnackbar(this.IsEngLish ? 'Allowed attempts must be an integer greater than or equal to 1.' : 'Số lần được làm bài phải là số nguyên lớn hơn hoặc bằng 1.', 'error')
                return
            }
            if (!this.canSubmitAssignment) {
                this.showSnackbar(this.IsEngLish ? 'Please select at least 1 class, 1 student, or 1 teacher to update permissions!' : 'Vui lòng chọn ít nhất 1 lớp, 1 học sinh hoặc 1 giáo viên để cập nhật phân quyền!', 'error')
                return
            }

            const dlg = this._confirm()
            if (dlg && typeof dlg.show === 'function') {
                const ok = await dlg.show({
                    title: this.isPermissionOnlyUpdate ? (this.IsEngLish ? 'Confirm update permissions' : 'Xác nhận cập nhật phân quyền') : (this.IsEngLish ? 'Confirm assignment' : 'Xác nhận giao bài'),
                    text: this._buildAssignSummary(),
                })
                if (!ok) return
            }

            const success = await this._doAssign()
            if (!success) return
            
            this.isOpenDialogForAssignToStudent = false
            // Case chỉ cập nhật quyền được giữ lại trong trình soạn để giáo viên tiếp tục chỉnh bài.
            if (!this.isPermissionOnlyUpdate) {
                if (window !== window.top) {
                    window.parent.postMessage({ type: 'iframeRef_closeWindow' }, '*')
                } else {
                    window.open('/lms-teacher-dashboard', '_parent')
                }
            }
        },
        _confirm() {
            if (this.confirmRef?.value?.show) {
                return this.confirmRef.value
            }
            return {
                show: async ({ text, title }) => {
                    return window.confirm((title ? title + '\n\n' : '') + (text || 'Bạn có chắc chắn muốn giao bài không?'))
                }
            }
        },
        addComponent(componentInfo) {
            if (componentInfo?.type === 'SKILL_MATRIX') {
                const matrixGroup = {
                    id: `group_${crypto.randomUUID()}`,
                    title: 'Ma trận đề',
                    description: '',
                    media: {
                        type: 'YOUTUBE',
                        sourceYT: { id: '', source: '', name: '' },
                        sourceRecord: { id: '', source: '', name: '' },
                        sourceFiles: { file: [], image: [] },
                    },
                    questions: [],
                    questionSource: {
                        sourceType: 'CONTENT_HUB',
                        sourceKind: 'QUESTION_BANK_SKILL_MATRIX',
                        matrixMode: true,
                        matrixConfigs: [],
                        questionIds: [],
                        poolSize: 0,
                    },
                    questionSelection: {
                        mode: 'RANDOM',
                        matrixMode: true,
                        questionsPerAttempt: 0,
                    },
                }
                this.updateGroups([matrixGroup])
                this.selectedItem = { type: 'group', groupIndex: 0, qIndex: null }
                if (this.isMobile) {
                    this.isLibraryDrawerOpen = false
                }
                return
            }

            const newGroups = [...JSON.parse(JSON.stringify(this.assignment.AssignmentConfig.groups))]
            let ordinalNumber = 1
            let previousQuestion = 1
            for (let i = 0; i < newGroups.length; i++) {
                if (newGroups[i].questions.length > 0) {
                    ordinalNumber += newGroups[i].questions.length
                    previousQuestion = ordinalNumber
                } else {
                    ordinalNumber = previousQuestion
                }
            }

            const newQuestion = vueData.buildNewQuestion(componentInfo, ordinalNumber)

            if (newGroups.length > 0) {
                newGroups[newGroups.length - 1].questions.push(newQuestion)
            } else {
                newGroups.push({
                    id: `group_${crypto.randomUUID()}`,
                    title: 'Phần 1',
                    description: '',
                    media: {
                        type: 'YOUTUBE',
                        sourceYT: {
                            id: '',
                            source: '',
                            name: '',
                        },
                        sourceRecord: {
                            id: '',
                            source: '',
                            name: '',
                        },
                        sourceFiles: {
                            file: [],
                            image: [],
                        },
                    },
                    questions: [newQuestion],
                })
            }
            this.updateGroups(newGroups)
            this.selectedItem = { type: 'question', groupIndex: newGroups.length - 1, qIndex: newGroups[newGroups.length - 1].questions.length - 1 }
            if (this.isMobile) {
                this.isLibraryDrawerOpen = false
            }
        },
        isContentHubOrigin(source, owner) {
            const sourceTypes = [
                source?.sourceTracking?.sourceType,
                owner?.sourceTracking?.sourceType,
                source?.sourceType,
                source?.origin,
            ]
            // HOC_LIEU_SO là schema cũ của luồng học liệu; cũng là nguồn dùng chung
            // nên xóa khỏi bài chỉ được gỡ liên kết, không được xóa file gốc.
            return sourceTypes.some(type => ['CONTENT_HUB', 'HOC_LIEU_SO'].includes(String(type || '').trim().toUpperCase()))
        },
        mediaSourceEntries(media, owner) {
            if (!media) return []
            const entries = []
            const add = source => {
                if (source && (source.source || source.id || source.externalId || source.dbFileId || source.resourceNodeId)) {
                    entries.push({ source, owner })
                }
            }
            add(media.sourceYT)
            add(media.sourceRecord)
            ;['file', 'image'].forEach(type => (media.sourceFiles?.[type] || []).forEach(add))
            return entries
        },
        removedElementMediaEntries(element, kind) {
            if (kind === 'group') {
                return [
                    ...this.mediaSourceEntries(element?.media, element),
                    ...(element?.questions || []).flatMap(question => this.mediaSourceEntries(question?.config?.media, question)),
                ]
            }
            return this.mediaSourceEntries(element?.config?.media, element)
        },
        mediaSourceKeys(source) {
            return [
                source?.externalId ? `external:${source.externalId}` : '',
                source?.dbFileId ? `db:${source.dbFileId}` : '',
                source?.resourceFileId ? `resource:${source.resourceFileId}` : '',
                source?.id ? `id:${source.id}` : '',
            ].filter(Boolean)
        },
        assignmentMediaEntries(groups) {
            return (groups || []).flatMap(group => [
                ...this.mediaSourceEntries(group?.media, group),
                ...(group?.questions || []).flatMap(question => this.mediaSourceEntries(question?.config?.media, question)),
            ])
        },
        deleteExternalWithManager(manager, method, fileId, accessToken) {
            // UploadManager cũ dùng callback và có thể nuốt lỗi; bọc lại để không
            // xóa element khỏi editor khi file bên thứ ba chưa được xác nhận xóa.
            return new Promise((resolve, reject) => manager[method](fileId, {
                accessToken,
                onComplete: resolve,
                onError: reject,
            }))
        },
        async deleteAssignmentMediaSource(source) {
            const manager = window.UploadManager
            if (source?.resourceNodeId) {
                await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: source.resourceNodeId }, { cache: false })
            }

            // Chỉ file do bài tập upload mới được xóa khỏi YouTube/Google Drive.
            // URL nhập tay hoặc file Content Hub không đi vào nhánh này.
            const sourceUrl = source?.externalSource || source?.source || ''
            const isYoutubeSource = source?.mediaProvider === 'youtube'
                || (source?.mediaSource === 'upload' && /youtube\.com|youtu\.be/i.test(sourceUrl))
            const externalId = source?.externalId || (source?.mediaSource === 'upload' ? source.id : '')
            const needsManager = Boolean(externalId || source?.dbFileId || source?.resourceFileId || (source?.id && source.mediaSource === 'db'))
            if (needsManager && !manager) throw new Error('UploadManager chưa được khởi tạo')
            if (externalId) {
                const token = await fetchPromise('lms/FP_Youtube_Token_Get', {}, { forceRefresh: true, cache: false })
                await this.deleteExternalWithManager(
                    manager,
                    isYoutubeSource ? 'deleteFromYouTube' : 'deleteFromGoogleDrive',
                    externalId,
                    token?.access_token,
                )
            }

            // File upload được lưu thêm ở LMS FileData, độc lập với việc đã có
            // resourceNodeId hay chưa; phải dọn bản này để không tạo file mồ côi.
            const dbFileId = source?.dbFileId || (source?.mediaSource === 'db' ? source.id : '')
            if (dbFileId) await manager.deleteLmsFileData(dbFileId)
            if (source?.resourceFileId && source.resourceFileId !== dbFileId) {
                // Tương thích dữ liệu cũ từng lưu bản sao bằng API LMS File.
                await manager.deleteLmsFile(source.resourceFileId)
            }
        },
        async cleanupRemovedElementMedia(entries, remainingGroups) {
            const remainingKeys = new Set(this.assignmentMediaEntries(remainingGroups).flatMap(({ source }) => this.mediaSourceKeys(source)))
            const cleanedKeys = new Set()
            for (const { source, owner } of entries) {
                // Media lấy từ Content Hub là tài sản dùng chung: chỉ xóa liên kết
                // khỏi bài đang soạn, tuyệt đối không xóa node/file nguồn.
                if (this.isContentHubOrigin(source, owner)) continue
                const keys = this.mediaSourceKeys(source)
                if (keys.some(key => remainingKeys.has(key) || cleanedKeys.has(key))) continue
                try {
                    await this.deleteAssignmentMediaSource(source)
                    keys.forEach(key => cleanedKeys.add(key))
                } catch (error) {
                    console.error('Lỗi dọn media khi xóa element:', error)
                    this.showSnackbar(error?.message || 'Không thể xóa media của element.', 'error')
                    return false
                }
            }
            return true
        },
        async handleCanvasQuestionRemove({ groupIndex, qIndex, question }) {
            if (this.isDeletingElement) return
            const currentGroups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const currentQuestion = currentGroups[groupIndex]?.questions?.[qIndex]
            if (!currentQuestion) return
            this.isDeletingElement = true
            try {
                const removedQuestion = question || currentQuestion
                currentGroups[groupIndex].questions.splice(qIndex, 1)
                const cleaned = await this.cleanupRemovedElementMedia(
                    this.removedElementMediaEntries(removedQuestion, 'question'),
                    currentGroups,
                )
                if (!cleaned) return
                this.updateGroups(currentGroups)
                this.selectedItem = null
            } finally {
                this.isDeletingElement = false
            }
        },
        async handleCanvasGroupRemove({ groupIndex, group }) {
            if (this.isDeletingElement) return
            const currentGroups = JSON.parse(JSON.stringify(this.assignment?.AssignmentConfig?.groups || []))
            const currentGroup = currentGroups[groupIndex]
            if (!currentGroup) return
            this.isDeletingElement = true
            try {
                const removedGroup = group || currentGroup
                const remainingGroups = currentGroups.filter((_, index) => index !== groupIndex)
                const cleaned = await this.cleanupRemovedElementMedia(
                    this.removedElementMediaEntries(removedGroup, 'group'),
                    remainingGroups,
                )
                if (!cleaned) return
                this.updateGroups(remainingGroups)
                this.selectedItem = null
            } finally {
                this.isDeletingElement = false
            }
        },
        updateGroups(newGroups) {
            const mappedGroups = newGroups.map((item) => {
                // Khi câu nguồn bị xóa/di chuyển, giữ questionSource đồng bộ với snapshot
                // đang nằm trong nhóm để số pool và danh sách được phép bốc không bị lệch.
                if (Array.isArray(item.questionSource?.questionIds)) {
                    const sourceQuestionIds = new Set((item.questions || [])
                        .map(question => question?.sourceTracking?.questionId ?? question?.sourceTracking?.sourceQuestionId)
                        .filter(id => id !== undefined && id !== null)
                        .map(String))
                    const questionIds = item.questionSource.questionIds.filter(id => sourceQuestionIds.has(String(id)))
                    if (questionIds.length) {
                        item = { ...item, questionSource: { ...item.questionSource, questionIds, poolSize: questionIds.length } }
                    } else {
                        // Không còn câu nào của file nguồn: chuyển về chế độ thủ công để
                        // không vô tình bốc các câu được thêm riêng sau đó.
                        const remainingQuestions = item.questions?.length || 0
                        item = { ...item, questionSource: undefined, questionSelection: { ...(item.questionSelection || {}), mode: 'ALL', questionsPerAttempt: remainingQuestions || 1 } }
                    }
                }
                if (!item.media) {
                    let media = {
                        type: 'YOUTUBE',
                        sourceYT: {
                            id: '',
                            source: '',
                            name: '',
                        },
                        sourceRecord: {
                            id: '',
                            source: '',
                            name: '',
                        },
                        sourceFiles: {
                            file: [],
                            image: [],
                        },
                    }
                    return { ...item, media }
                } else {
                    return item
                }
            })
            this.assignment = {
                ...this.assignment,
                AssignmentConfig: {
                    ...(this.assignment.AssignmentConfig || {}),
                    groups: mappedGroups
                }
            }
            this.scheduleAutoSave()
        },
        async handleSave(isPublishing) {
            console.log('luu......')
            const groups = this.assignment.AssignmentConfig.groups
            const invalidRandomSelection = groups.find(group => {
                const selection = group.questionSelection || {}
                if (selection.mode !== 'RANDOM') return false
                const count = Number(selection.questionsPerAttempt)
                const poolSize = this.getRandomPoolSize(group)
                return !Number.isInteger(count) || count < 1 || count > poolSize
            })
            if (invalidRandomSelection) {
                // Không cho lưu cấu hình lấy nhiều câu hơn pool; nếu không submission
                // sẽ không thể tạo đủ số câu đã cài khi học sinh bắt đầu làm.
                const poolSize = this.getRandomPoolSize(invalidRandomSelection)
                const totalQuestions = invalidRandomSelection.questions?.length || 0
                const poolDescription = poolSize < totalQuestions
                    ? `kho ngẫu nhiên có ${poolSize}/${totalQuestions} câu trong nhóm`
                    : `kho có ${poolSize} câu`
                this.showSnackbar(`Nhóm "${invalidRandomSelection.title || 'câu hỏi'}" ${poolDescription}; số câu lấy phải từ 1 đến ${poolSize}.`, 'warning')
                return false
            }
            if (!this.assignment.ExternalLink) {
                const { message, isNotChoose } = vueData.isCheckGroupHasAnswerQuestionNotChoose(groups)
                if (isNotChoose) {
                    this.showSnackbar(message + ' chưa có đáp án. Vui lòng kiểm tra lại.', 'warning')
                    return
                }
            } else {
                const link = this.assignment.ExternalLink.trim()
                const maxScore = Number(this.assignment.MaxScore)
                
                if (link === '') {
                    this.showSnackbar('Vui lòng nhập link bài tập.', 'warning')
                    return
                }

                if (!this.assignment.MaxScore || isNaN(maxScore) || maxScore <= 0) {
                    this.showSnackbar('Vui lòng nhập thang điểm tối đa hợp lệ.', 'warning')
                    return
                }

                // Kiểm tra domain theo nguồn tích hợp
                if (this.assignment.IntegrationSource === 'AZOTA' && !link.includes('azota.vn')) {
                    this.showSnackbar('Đường dẫn không hợp lệ. Vui lòng nhập link từ Azota (azota.vn).', 'warning')
                    return
                }
                if (this.assignment.IntegrationSource === 'ETEST' && !link.includes('etest.lhbs.vn')) {
                    this.showSnackbar('Đường dẫn không hợp lệ. Vui lòng nhập link từ Etest (etest.lhbs.vn).', 'warning')
                    return
                }
            }
            const isIntegration = this.assignment.IntegrationSource && this.assignment.IntegrationSource !== 'LMS'
            const isNotFullQuiz = (isIntegration || this.assignment.ExternalLink) ? true : vueData.isCheckAllGroupFullQuiz(groups)
            const payload = {
                assignment: this.assignment,
                isPublishing: isPublishing,
                Is_Full_Quiz: !isNotFullQuiz,
                setting: this.setting,
            }
            console.log('payload', payload)
            // Cancel any pending auto-save and guard against concurrent saves
            clearTimeout(this.autoSaveTimer)
            if (this.isSaving) return false
            this.isSaving = true
            try {
                this.autoSaveStatus = 'saving'
                const res = await this.onSave(payload)
                if (!res) {
                    this.autoSaveStatus = null
                    return false
                }
                this.lastSavedAt = Date.now()
                this.relativeTimeNow = Date.now()
                this.autoSaveStatus = 'saved'
                clearInterval(this.relativeTimeTimer)
                this.relativeTimeTimer = setInterval(() => {
                    this.relativeTimeNow = Date.now()
                }, 10000)
                return true
            } finally {
                this.isSaving = false
            }
        },
        // ==== Helpers hiển thị ====
        formattedDate(dateStr) {
            return dateStr ? dayjs(dateStr).format('DD/MM/YYYY') : ''
        },
        formattedTime(timeStr) {
            return timeStr ? dayjs(timeStr, 'HH:mm').format('HH:mm') : ''
        },
        formatDate(dateStr) {
            if (!dateStr) return '—'
            const d = dayjs(dateStr)
            return d.isValid() ? d.format('DD/MM/YYYY HH:mm') : String(dateStr)
        },
        getDue(d) {
            if (!d.date || !d.time) return null

            const dateObj = dayjs(d.date) // parse ISO date
            const [hour, minute] = d.time.split(':').map(Number)

            return dateObj.hour(hour).minute(minute).second(0).format('YYYY-MM-DD HH:mm:ss')
        },

        openDate() {
            if (!this.deadlines) this.deadlines = { date: null, time: null }
            this.dateDialogVisible = true
        },

        openTime() {
            if (!this.deadlines) this.deadlines = { date: null, time: null }
            this.timeDialogVisible = true
        },
        async loadDSHocSinhByDSLopID(DSLopID) {
            const assignmentID = vueData.AssignmentID || this.assignment?.AssignmentID || 0
            try {
                const response = await fetchPromise('/lms/HocSinhLop_GetByLopIDList', { 
                    DSLopID, 
                    AssignmentID: assignmentID,
                    NienKhoa: Number(vueData.assignment?.NienKhoa ?? vueData.NienKhoa ?? 0)
                }, { cache: false })
                const students = (Array.isArray(response) ? response : []).flat(Infinity)
                return students.map(item => ({ ...item, isSelected: false, disabled: [true, 1, '1'].includes(item.Is_Assigned) }))
            } catch (error) {
                this.showSnackbar(error?.Message || error?.message || 'Không thể tải danh sách học sinh.', 'error')
                return []
            }
        },
        async _doAssign() {
            this.isLoadDSHocSinh = true
            try {
                const d = { date: this.deadlines?.date, time: this.deadlines?.time }
                const due = this.getDue(d)
                const groups = this.assignment.AssignmentConfig.groups
                const isIntegration = this.assignment.IntegrationSource && this.assignment.IntegrationSource !== 'LMS'
                const isNotFullQuiz = (isIntegration || this.assignment.ExternalLink) ? true : vueData.isCheckAllGroupFullQuiz(groups)
                
                // Nếu có lớp/học sinh mới thì lưu bài trước khi giao như flow cũ.
                // Với case chỉ cập nhật quyền, AssignmentID đã có sẵn và không cần ghi lại nội dung bài.
                if (!this.isPermissionOnlyUpdate) {
                    const success = await this.handleSave(true)
                    if (!success) {
                        this.isLoadDSHocSinh = false
                        return false
                    }
                }

                await new Promise((resolve) => setTimeout(resolve, 500))
                const assignPromises = []

                if (this.DSHocSinhSelected.length > 0) {
                    const payload = this.DSHocSinhSelected.map(item => ({
                        LopID: item.LopID,
                        HocSinhID: item.HocSinhID,
                        DueDate: due,
                        MaxScore: Number(this.totalScoreAsm),
                        Status: 2,
                        ResourceType: 'ASSIGNMENT',
                        ResourceID: Number(vueData.AssignmentID),
                        LimitAssigned: Number(this.limitAssigned),
                        Is_Full_Quiz: !isNotFullQuiz ? 1 : 0,
                    }))
                    assignPromises.push(fetchPromise('lms/EL_Teacher_AssignToStudent', {
                        AssignmentID: Number(vueData.AssignmentID),
                        JsonStudentItems: JSON.stringify(payload)
                    }, { cache: false }))
                }
                if (this.selectedClass.length > 0 || this.isPermissionOnlyUpdate) {
                    const payload = this.selectedClass.map(id => ({
                        LopID: id,
                        DueDate: due,
                        MaxScore: Number(this.totalScoreAsm),
                        Status: 2,
                        ResourceType: 'ASSIGNMENT',
                        ResourceID: Number(vueData.AssignmentID),
                        LimitAssigned: Number(this.limitAssigned),
                        Is_Full_Quiz: !isNotFullQuiz ? 1 : 0,
                    }))
                    // API dùng chung cho giao lớp cũng xử lý ListTeacherPermission theo AssignmentID.
                    // Gửi mảng lớp rỗng để cập nhật quyền riêng, không tạo thêm lượt giao bài.
                    assignPromises.push(fetchPromise('lms/EL_Teacher_AssignToClasses_CLASS', {
                        AssignmentID: Number(vueData.AssignmentID),
                        JsonClassItems: JSON.stringify(payload),
                        ListTeacherPermission: this.GiaoVienPermissionSelected.length > 0 ? this.GiaoVienPermissionSelected.join(',') : '',
                    }, { cache: false }))
                }
                
                await Promise.all(assignPromises)
                this.showSnackbar(this.isPermissionOnlyUpdate ? (this.IsEngLish ? 'Teacher permissions updated successfully!' : 'Cập nhật phân quyền giáo viên thành công!') : (this.IsEngLish ? 'Saved and assigned successfully!' : 'Lưu bài và giao bài thành công!'), 'success')
                return true
            } catch (err) {
                console.error('Assign error:', err)
                this.showSnackbar(err?.Message || err?.message || (this.IsEngLish ? 'Error assigning assignment' : 'Có lỗi khi giao bài'), 'error')
                return false
            } finally {
                this.isLoadDSHocSinh = false
            }
        },
        _buildAssignSummary() {
            const lines = []
            if (this.selectedClass.length > 0) {
                const lopThong = []
                const lopNhom = []
                this.selectedClass.forEach((id) => {
                    const lop = this.classOptions.find((c) => c.LopID == id)
					const tenLop = lop?.TenLopDisplay || lop?.TenLop || id
                    const isNhom = this.DSHocSinhByLopID.some((hs) => hs.LopID == id && hs.IsNhom)
                    isNhom ? lopNhom.push(tenLop) : lopThong.push(tenLop)
                })
                if (lopThong.length) lines.push(`• ${lopThong.length} ${this.IsEngLish ? 'classes' : 'lớp'}: ${lopThong.join(', ')}`)
                if (lopNhom.length) lines.push(`• ${lopNhom.length} ${this.IsEngLish ? 'groups' : 'nhóm'}: ${lopNhom.join(', ')}`)
            }
            if (this.DSHocSinhSelected.length > 0) {
                lines.push(`• ${this.DSHocSinhSelected.length} ${this.IsEngLish ? 'individual students' : 'học sinh riêng lẻ'}`)
            }
            if (this.GiaoVienPermissionSelected.length > 0) {
                const teacherNames = this.GiaoVienPermissionSelected.map(id => {
                    const teacher = this.DSGiaoVien_Permission.find(item => String(item.GiaoVienID) === String(id))
                    return teacher?.HoTenGV || id
                })
                lines.push(`• ${this.isPermissionOnlyUpdate ? (this.IsEngLish ? 'Update permissions for' : 'Cập nhật quyền cho') : (this.IsEngLish ? 'Assign permissions to' : 'Phân quyền cho')} ${teacherNames.join(', ')}`)
            }
            return lines.join('\n')
        },
        classDisabledReason(LopID) {
            if (this.DSHocSinhAssigned.some((hs) => hs.LopID == LopID)) return this.IsEngLish ? 'This class has already been assigned' : 'Lớp này đã được giao bài trước đó'
            if (this.DSHocSinhSelected.some((hs) => hs.LopID == LopID)) return this.IsEngLish ? 'Individual students in this class have already been selected' : 'Đã chọn học sinh riêng lẻ trong lớp này'
            return ''
        },
        async loadDSHocSinhAssignedByLopID(LopID) {
            try {
                const response = await fetchPromise('/lms/Teacher_GetDSHocSinh_AssignToStudent_ByLopID', { 
                    LopID, 
                    AssignmentID: vueData.AssignmentID,
                    NienKhoa: Number(vueData.assignment?.NienKhoa ?? vueData.NienKhoa ?? 0)
                }, { cache: false })
                return Array.isArray(response) ? response.flat(Infinity) : []
            } catch (error) {
                this.showSnackbar(error?.Message || error?.message || 'Không thể tải học sinh đã giao bài.', 'error')
                return []
            }
        },
        async loadDSGiaoVien_Permission() {
            let data = []
            try {
                data = await fetchPromise('/lms/EL_Teacher_GetTeacherByMonHocID',
                    {
                        MonHocID: vueData.assignment.MonHocID,
                        AssignmentID: vueData.AssignmentID,
                        HocKi: vueData.HocKi,
                    }, { cache: false })
            } catch (error) {
                this.showSnackbar(error?.Message || error?.message || 'Không thể tải danh sách giáo viên phân quyền.', 'error')
            }
            this.DSGiaoVien_Permission = data
        },
    },
    watch: {
        isPropertiesDrawerOpen: {
            handler(value) { this.setIframeCloseHidden(value) },
            immediate: true,
        },
        'assignment.ExternalLink'(v) {
            if (v && v.trim() !== '') {
                this.assignment.AssignmentType = 'INTEGRATED'
            } else {
                this.assignment.AssignmentType = 'LMS'
            }
        },
        initialAssignment: {
            handler(newVal) {
                if (newVal) {
                    // Prevent the deep assignment watcher from triggering auto-save on initial load
                    this._skipNextAutoSave = true
                    this.assignment = JSON.parse(JSON.stringify(newVal))
					this.loadHocLieuMapping(newVal.AssignmentID)
                }
            },
            immediate: true,
        },

        selectedItem: function (item) {
            this.fileAudio = null
            if (item) {
                const group = this.assignment?.AssignmentConfig?.groups?.[item.groupIndex]
                const isMatrix = group?.questionSource?.sourceKind === 'QUESTION_BANK_SKILL_MATRIX' ||
                    group?.questionSource?.matrixMode === true ||
                    group?.questionSelection?.matrixMode === true
                if (item.type === 'group' && isMatrix) {
                    this.isPropertiesDrawerOpen = false
                } else {
                    this.isPropertiesDrawerOpen = true
                }
            }
        },
        assignment: {
            handler(newVal) {
                if (newVal && this.isEditMode) {
                    vueData.AssignmentDataLog = _.cloneDeep(newVal)
                }
                this.scheduleAutoSave()
            },
            deep: true,
        },
        selectedClass: {
            handler(newVal) {
                if (this.selectedClass.length > 0) {
                    this.DSHocSinhSelected = this.DSHocSinhSelected.filter((item) => !this.selectedClass.includes(item.LopID))
                }
            },
            deep: true,
        },
        isOpenDialogForAssignToStudent: {
            async handler(newVal) {
                if (newVal) {
                    if (this.isMatrixAssignment) {
                        this.limitAssigned = 1
                    }
                    this.GiaoVienPermissionSelected = []
                    let DSLop = JSON.stringify(this.filteredClassOptions.map((item) => item.LopID))
                    this.DSHocSinhByLopID = await this.loadDSHocSinhByDSLopID(DSLop)
                    console.log('this.DSHocSinhByLopID', this.DSHocSinhByLopID)
                    this.loadDSGiaoVien_Permission()
                } else {
                    this.deadlines = {
                        date: null,
                        time: null,
                    }
                }
            },
            deep: true,
        },
    },
	}
</script>
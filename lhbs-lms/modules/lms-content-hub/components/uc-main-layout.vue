<template>
	<Global upload-manager>
		<template #header>
			<v-card>
				<v-card-text class="d-flex align-center ga-2 flex-wrap py-2">
					<span class="text-subtitle-1 font-weight-bold">Kho soạn nội dung</span>
					<template v-if="activeBranch === 'initiative'">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<span class="text-body-2 text-medium-emphasis">Sáng kiến</span>
					</template>
					<template v-else-if="activeBranch === 'profile'">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<span class="text-body-2 text-medium-emphasis">Hồ sơ</span>
					</template>
					<template v-else-if="selectedMon">
						<v-icon size="small" class="text-medium-emphasis">mdi-chevron-right</v-icon>
						<v-chip size="small" color="primary" variant="tonal">{{ selectedMon.TenMonHoc_HienThi || selectedMon.MonHocName }}</v-chip>
					</template>
					<v-spacer />
					<v-btn size="small" variant="outlined" color="primary" prepend-icon="mdi-refresh" :loading="isRefreshing" @click="refreshData">
						Làm mới
					</v-btn>
				</v-card-text>
			</v-card>
		</template>

		<v-divider />

			<v-row no-gutters class="content-hub-layout">
			<!-- Cây này dùng chung quy ước với gv-quan-ly-tai-nguyen và Question Bank. -->
			<v-col cols="12" md="3" lg="2" class="content-hub-sidebar">
				<!-- Menu nhánh luôn đứng yên; chỉ phần nội dung bên dưới mới được phép cuộn. -->
				<v-list density="compact" nav class="pa-2 content-hub-sidebar-menu flex-shrink-0">
					<!-- Hồ sơ dùng cùng cây node của LMS nhưng thư mục do người dùng tự tạo, không phụ thuộc Khối/Môn. -->
					<v-list-item rounded="lg" :active="activeBranch === 'profile'" prepend-icon="mdi-folder-multiple-outline" title="Hồ sơ" subtitle="Kho lưu trữ cá nhân" @click="selectBranch('profile')" />
					<v-list-item rounded="lg" :active="activeBranch === 'initiative'" prepend-icon="mdi-lightbulb-outline" title="Sáng kiến" subtitle="Tài nguyên độc lập" @click="selectBranch('initiative')" />
					<v-list-item rounded="lg" :active="activeBranch === 'subject'" prepend-icon="mdi-format-list-group" title="Khối môn" subtitle="Tài liệu và câu hỏi" @click="selectBranch('subject')" />
				</v-list>

				<v-divider class="flex-shrink-0" />

				<div v-if="activeBranch === 'subject'" class="pa-2 content-hub-branch-section">
					<div class="text-subtitle-2 font-weight-bold px-2 py-2">Khối môn</div>
					<div v-if="treeLoading" class="d-flex justify-center py-6">
						<v-progress-circular size="24" indeterminate />
					</div>
					<v-list v-else density="compact" nav>
						<template v-for="khoi in treeKhoi" :key="khoi.KhoiID">
							<v-list-item rounded="lg" class="mb-1" @click="toggleKhoi(khoi)">
								<template #prepend>
									<v-icon size="small">{{ khoi._open ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
								</template>
								<v-list-item-title class="text-body-2 font-weight-medium">{{ khoi.TenKhoiHoc || ('Khối ' + khoi.KhoiID) }}</v-list-item-title>
							</v-list-item>
							<template v-if="khoi._open">
								<v-list-item v-for="mon in khoi.children" :key="mon.MonHocID" rounded="lg" class="mb-1 pl-8" :active="selectedMon?.MonHocID === mon.MonHocID && selectedMon?.KhoiID === mon.KhoiID" color="primary" @click.stop="selectMonHoc(mon)">
									<v-list-item-title class="text-caption">{{ mon.TenMonHoc_HienThi || mon.MonHocName }}</v-list-item-title>
								</v-list-item>
							</template>
							<div v-if="khoi._open && !khoi.children.length" class="text-caption text-medium-emphasis pl-8 py-2">Không có môn học</div>
						</template>
						<div v-if="!treeKhoi.length" class="text-caption text-medium-emphasis pa-3">Chưa có context Khối/Môn</div>
					</v-list>
				</div>

				<div v-else-if="activeBranch === 'initiative'" class="content-hub-branch-section">
					<!-- Chỉ BGH/Admin được xem sáng kiến của giáo viên; luồng giám sát này chỉ đọc. -->
					<template v-if="isBGHUser">
						<div class="px-2 pt-2">
							<div class="d-flex align-center justify-space-between px-1 mb-2">
								<div class="text-subtitle-2 font-weight-bold">Sáng kiến</div>
								<v-chip size="x-small" color="primary" variant="flat">BGH</v-chip>
							</div>
							<v-btn-toggle :model-value="initiativeMode" mandatory density="compact" color="primary" variant="outlined" divided class="profile-mode-toggle mb-3" @update:model-value="selectInitiativeMode">
								<v-btn value="personal" size="small"><v-icon start size="small">mdi-account-outline</v-icon>Cá nhân</v-btn>
								<v-btn value="teachers" size="small"><v-icon start size="small">mdi-account-group-outline</v-icon>Giáo viên</v-btn>
							</v-btn-toggle>
						</div>
						<div v-if="initiativeMode === 'teachers'" class="profile-bgh-teacher-section">
							<div class="px-2">
								<v-text-field v-model="initiativeTeacherSearchQuery" placeholder="Tìm giáo viên..." density="compact" variant="outlined" prepend-inner-icon="mdi-magnify" hide-details clearable class="mb-2" />
								<div class="text-caption text-medium-emphasis px-1 mb-1 font-weight-medium">Danh sách giáo viên ({{ filteredInitiativeTeachers.length }})</div>
							</div>
							<v-list density="compact" nav class="pa-0 profile-teacher-list">
								<v-list-item v-for="teacher in filteredInitiativeTeachers" :key="teacher.UserID" rounded="lg" :active="selectedTeacherInitiative?.UserID === teacher.UserID" color="primary" class="mb-1 mx-2" @click="selectTeacherInitiative(teacher)">
									<template #prepend>
									<v-avatar size="28" color="primary" variant="tonal" class="d-flex align-center justify-center text-caption font-weight-bold mr-2">
											<!-- Avatar dùng GiaoVienID để ghép đúng endpoint ảnh; lỗi hoặc chưa có ảnh thì quay về chữ cái đầu. -->
											<v-img v-if="teacherAvatarUrl(teacher)" :src="teacherAvatarUrl(teacher)" :alt="teacher.FullName || teacher.UserID" cover>
											<!-- Lấp đầy slot ảnh để chữ cái dự phòng luôn nằm chính giữa avatar. -->
											<template #placeholder><span class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span></template>
											<template #error><span class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span></template>
											</v-img>
										<span v-else class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span>
										</v-avatar>
									</template>
									<v-list-item-title class="text-body-2 font-weight-medium">{{ teacher.FullName }}</v-list-item-title>
									<v-list-item-subtitle class="text-caption text-medium-emphasis">{{ teacher.UserID }} · {{ teacher.fileCount }} sáng kiến</v-list-item-subtitle>
								</v-list-item>
								<div v-if="!filteredInitiativeTeachers.length" class="text-caption text-medium-emphasis text-center py-6">Không tìm thấy giáo viên</div>
							</v-list>
						</div>
						<div v-else class="pa-2"><div class="text-caption text-medium-emphasis px-2">Kho tài liệu sáng kiến cá nhân của bạn.</div></div>
					</template>
					<template v-else>
						<div class="pa-2"><div class="text-subtitle-2 font-weight-bold px-2 py-2">Tài nguyên Sáng kiến</div><div class="text-caption text-medium-emphasis px-2">Tài liệu sáng kiến kinh nghiệm của riêng bạn.</div></div>
					</template>
				</div>
				<div v-else class="content-hub-branch-section">
					<!-- BGH/Tổ trưởng/Admin được chọn xem Hồ sơ theo từng giáo viên; các thao tác ghi bị ẩn ở chế độ giám sát. -->
					<template v-if="isProfileSupervisor">
						<div class="px-2 pt-2">
							<div class="d-flex align-center justify-space-between px-1 mb-2">
								<div class="text-subtitle-2 font-weight-bold">Hồ sơ</div>
								<v-chip size="x-small" color="primary" variant="flat">Giám sát</v-chip>
							</div>
							<v-btn-toggle :model-value="profileMode" mandatory density="compact" color="primary" variant="outlined" divided class="profile-mode-toggle mb-3" @update:model-value="selectProfileMode">
								<v-btn value="personal" size="small"><v-icon start size="small">mdi-account-outline</v-icon>Cá nhân</v-btn>
								<v-btn value="teachers" size="small"><v-icon start size="small">mdi-account-group-outline</v-icon>Giáo viên</v-btn>
							</v-btn-toggle>
						</div>
						<div v-if="profileMode === 'teachers'" class="profile-bgh-teacher-section">
							<div class="px-2">
								<v-text-field v-model="teacherSearchQuery" placeholder="Tìm giáo viên..." density="compact" variant="outlined" prepend-inner-icon="mdi-magnify" hide-details clearable class="mb-2" />
								<div class="text-caption text-medium-emphasis px-1 mb-1 font-weight-medium">Danh sách giáo viên ({{ filteredProfileTeachers.length }})</div>
							</div>
							<v-list density="compact" nav class="pa-0 profile-teacher-list">
								<v-list-item v-for="teacher in filteredProfileTeachers" :key="teacher.UserID" rounded="lg" :active="selectedTeacherProfile?.UserID === teacher.UserID" color="primary" class="mb-1 mx-2" @click="selectTeacherProfile(teacher)">
									<template #prepend>
									<v-avatar size="28" color="primary" variant="tonal" class="d-flex align-center justify-center text-caption font-weight-bold mr-2">
											<!-- Hồ sơ và Sáng kiến dùng chung quy tắc avatar để mã giáo viên luôn map về đúng ảnh. -->
											<v-img v-if="teacherAvatarUrl(teacher)" :src="teacherAvatarUrl(teacher)" :alt="teacher.FullName || teacher.UserID" cover>
											<!-- Lấp đầy slot ảnh để chữ cái dự phòng luôn nằm chính giữa avatar. -->
											<template #placeholder><span class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span></template>
											<template #error><span class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span></template>
											</v-img>
										<span v-else class="d-flex align-center justify-center w-100 h-100">{{ teacherInitial(teacher) }}</span>
										</v-avatar>
									</template>
									<v-list-item-title class="text-body-2 font-weight-medium">{{ teacher.FullName }}</v-list-item-title>
									<v-list-item-subtitle class="text-caption text-medium-emphasis">{{ teacher.UserID }} · {{ teacher.fileCount }} file</v-list-item-subtitle>
								</v-list-item>
								<div v-if="!filteredProfileTeachers.length" class="text-caption text-medium-emphasis text-center py-6">Không tìm thấy giáo viên</div>
							</v-list>
						</div>
						<div v-else class="pa-2"><div class="text-caption text-medium-emphasis px-2">Kho lưu trữ cá nhân của bạn.</div></div>
					</template>
					<template v-else>
						<div class="pa-2"><div class="text-subtitle-2 font-weight-bold px-2 py-2">Hồ sơ cá nhân</div><div class="text-caption text-medium-emphasis px-2">Tạo thư mục theo cách của bạn và lưu file vào đúng vị trí.</div></div>
					</template>
				</div>
			</v-col>

			<v-col cols="12" md="9" lg="10" class="content-hub-main">
				<div class="d-flex align-center ga-2 flex-wrap pa-3">
					<div>
						<div class="d-flex align-center ga-2">
							<div class="text-subtitle-1 font-weight-bold">{{ activeBranch === 'initiative' ? (isInitiativeInspectionMode ? ('Sáng kiến giáo viên: ' + (selectedTeacherInitiative?.FullName || selectedTeacherInitiative?.UserID)) : 'Sáng kiến') : (activeBranch === 'profile' ? (isProfileInspectionMode ? ('Hồ sơ giáo viên: ' + (selectedTeacherProfile?.FullName || selectedTeacherProfile?.UserID)) : 'Hồ sơ') : (selectedMon?.TenMonHoc_HienThi || selectedMon?.MonHocName || 'Chưa chọn Khối/Môn')) }}</div>
							<!-- Hiển thị rõ khi người có quyền giám sát đang xem dữ liệu giáo viên ở chế độ chỉ đọc. -->
							<v-chip v-if="isProfileInspectionMode || isInitiativeInspectionMode" size="x-small" color="info" variant="tonal" prepend-icon="mdi-eye-outline">Giám sát (Chỉ đọc)</v-chip>
						</div>
						<div class="text-caption text-medium-emphasis">{{ currentContextDescription }}</div>
					</div>
					<v-spacer />
					<!-- Sáng kiến và Hồ sơ tải file trực tiếp vào LMS; Khối môn vẫn mở hộp thoại chọn loại tài liệu. -->
					<!-- Ẩn toàn bộ thao tác ghi khi BGH/Tổ trưởng đang xem dữ liệu của giáo viên. -->
					<v-btn v-if="activeSection === 'documents' && !isProfileInspectionMode && !isInitiativeInspectionMode" size="small" color="primary" :prepend-icon="activeBranch === 'subject' ? 'mdi-cloud-upload-outline' : 'mdi-file-upload-outline'" :disabled="!canUploadCurrentContext" @click="activeBranch === 'initiative' ? openInitiativeFilePicker() : (activeBranch === 'profile' ? openProfileFilePicker() : openUploadDialog())">{{ activeBranch === 'subject' ? 'Tải tài liệu lên' : 'Tải file lên' }}</v-btn>
					<v-btn v-if="activeBranch === 'profile' && activeSection === 'documents' && !isProfileInspectionMode && !isInitiativeInspectionMode" size="small" variant="tonal" color="primary" prepend-icon="mdi-folder-plus-outline" :disabled="!canUploadCurrentContext" @click="openCreateProfileFolder">Thư mục mới</v-btn>
					<!-- Không dùng chung input của các luồng Google Drive/iSpring để tránh lưu nhầm sang storage ngoài. -->
					<input ref="initiativeFileInput" type="file" multiple accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip,.rar,.html,.htm,image/*,audio/*,video/*" class="d-none" @change="uploadInitiativeFiles" />
					<input ref="profileFileInput" type="file" multiple accept=".pdf,.doc,.docx,.xls,.xlsx,.ppt,.pptx,.txt,.zip,.rar,.html,.htm,image/*,audio/*,video/*" class="d-none" @change="uploadProfileFiles" />
				</div>
				<v-divider />

				<div v-if="activeBranch === 'subject'" class="d-flex align-center px-3 content-hub-tabs-bar">
					<v-tabs v-model="activeSection" color="primary" class="flex-grow-1" density="comfortable">
						<v-tab value="documents"><v-icon start>mdi-file-document-multiple-outline</v-icon>Tài liệu</v-tab>
						<v-tab value="questions"><v-icon start>mdi-help-box-multiple-outline</v-icon>Ngân hàng câu hỏi</v-tab>
					</v-tabs>
					<!-- Trên mobile, mở nhóm ngay cạnh tab để bảng bên dưới luôn giữ trọn không gian. -->
					<!-- Tên nhóm đang chọn luôn hiện trên mobile để giáo viên biết bảng câu hỏi thuộc nhóm nào. -->
					<v-btn v-if="activeSection === 'questions'" class="d-lg-none content-hub-mobile-group-button" size="small" variant="tonal" color="primary" prepend-icon="mdi-folder-outline" :aria-label="'Mở nhóm câu hỏi. Nhóm hiện tại: ' + (selectedGroup?.Title || 'chưa chọn')" :title="selectedGroup?.Title || 'Chưa chọn nhóm câu hỏi'" @click="groupDrawer = true">{{ selectedGroup?.Title || 'Nhóm câu hỏi' }}</v-btn>
				</div>
				<v-divider v-if="activeBranch === 'subject'" />

				<div v-if="activeSection === 'documents'" class="content-hub-documents">
					<!-- Hồ sơ hiển thị folder hiện tại; các node THU_MUC không đi vào bảng file để giữ trải nghiệm giống Drive. -->
					<div v-if="activeBranch === 'profile'" class="profile-drive-toolbar d-flex align-center ga-2 flex-wrap px-3 pt-3">
						<v-btn v-if="profileCurrentFolderId" size="small" variant="text" prepend-icon="mdi-arrow-up" @click="openProfileFolderById(profileCurrentFolder?.ParentID || null)">Thư mục cha</v-btn>
						<v-breadcrumbs :items="profileBreadcrumbItems" density="compact" class="pa-0">
							<template #item="{ item }">
								<v-breadcrumbs-item :disabled="item.id === profileCurrentFolderId" :class="{ 'cursor-pointer': item.id !== profileCurrentFolderId }" @click="openProfileFolderById(item.id)">{{ item.title }}</v-breadcrumbs-item>
							</template>
						</v-breadcrumbs>
						<v-spacer />
						<!-- Cho phép người dùng chọn cách duyệt phù hợp: dạng thẻ trực quan hoặc dạng cây khi có nhiều folder lồng nhau. -->
						<v-btn-toggle v-model="profileViewMode" mandatory density="compact" color="primary" variant="outlined" divided>
							<v-btn value="cards" size="small" aria-label="Xem dạng thẻ"><v-icon start>mdi-view-grid-outline</v-icon>Dạng thẻ</v-btn>
							<v-btn value="tree" size="small" aria-label="Xem dạng cây"><v-icon start>mdi-file-tree-outline</v-icon>Dạng cây</v-btn>
						</v-btn-toggle>
					</div>
					<div v-if="activeBranch === 'profile' && profileViewMode === 'cards' && profileFolderItems.length" class="profile-folder-grid px-3 pt-2">
						<v-card v-for="folder in profileFolderItems" :key="folder.NoiDungID" variant="tonal" class="profile-folder-card" @click="enterProfileFolder(folder)">
							<!-- Lưới tự chia cột; card lấp đầy cột, còn py-1 giữ chiều cao gọn. -->
							<div class="d-flex align-center ga-2 px-2 py-1">
								<!-- Thẻ phản ánh cả file trong thư mục con để không khiến folder cha có dữ liệu bị hiểu nhầm là trống. -->
								<v-icon class="flex-shrink-0" :color="getProfileFolderCounts(folder.NoiDungID).totalFiles > 0 ? 'amber-darken-3' : 'amber-darken-1'">{{ getProfileFolderCardIcon(folder.NoiDungID) }}</v-icon>
								<div class="profile-folder-info">
									<!-- Khi có thư mục con, nhãn dùng cùng quy ước trực tiếp/tổng như Dạng cây. -->
									<div class="text-body-2 font-weight-medium profile-folder-name" :title="folder.TenNoiDung">{{ folder.TenNoiDung }}</div>
									<div class="text-caption text-medium-emphasis" :title="getProfileFolderCardCountTitle(folder.NoiDungID)">{{ getProfileFolderCardCountLabel(folder.NoiDungID) }}</div>
								</div>
								<!-- Gom Đổi tên/Xóa vào một icon menu ở mép phải; chế độ giám sát chỉ đọc không có menu này. -->
								<div v-if="!isProfileInspectionMode" class="flex-shrink-0">
									<v-menu location="bottom end">
										<template #activator="{ props }">
											<v-btn v-bind="props" icon size="small" variant="text" color="primary" :loading="deletingDocumentId === folder.NoiDungID" aria-label="Thao tác thư mục" @click.stop><v-icon>mdi-dots-vertical</v-icon><v-tooltip activator="parent" location="top">Thao tác thư mục</v-tooltip></v-btn>
										</template>
										<v-list density="compact" min-width="180">
											<v-list-item prepend-icon="mdi-pencil-outline" title="Đổi tên thư mục" :disabled="deletingDocumentId === folder.NoiDungID" @click.stop="openEditProfileFolder(folder)" />
											<v-list-item prepend-icon="mdi-delete-outline" title="Xóa thư mục" base-color="error" :disabled="deletingDocumentId === folder.NoiDungID" @click.stop="deleteProfileNode(folder)" />
										</v-list>
									</v-menu>
								</div>
							</div>
						</v-card>
					</div>
					<div v-if="activeBranch === 'profile' && profileViewMode === 'tree'" class="profile-folder-tree px-3 pt-2">
						<!-- Treeview dựng từ cùng danh sách node phẳng; không phát sinh cấu trúc DB riêng cho phần hiển thị. -->
						<!-- Dùng v-model để treeview giữ đúng node đang chọn; nếu chỉ truyền :activated, click node con có thể không cập nhật màu active. -->
						<v-treeview v-model:activated="profileActivatedTreeNodeIds" :items="profileFolderTree" item-title="TenNoiDung" item-value="NoiDungID" item-children="children" activatable open-on-click open-all density="compact" color="primary" class="border rounded pa-2" @update:activated="onProfileTreeActivated">
							<template #prepend="{ item }">
								<!-- Phân biệt icon root, folder có file (mdi-folder-text / mdi-folder) và folder rỗng (mdi-folder-outline). -->
								<v-icon :color="item.totalFiles > 0 ? 'amber-darken-3' : 'amber-darken-1'">
									{{ item.NoiDungID === 'profile-root' ? (item.totalFiles > 0 ? 'mdi-folder-multiple' : 'mdi-folder-multiple-outline') : (item.directFiles > 0 ? 'mdi-folder-text' : (item.totalFiles > 0 ? 'mdi-folder' : 'mdi-folder-outline')) }}
								</v-icon>
							</template>
							<!-- Title chặn click mặc định để đổi folder ngay; vì vậy class này tự phản chiếu profileCurrentFolderId để parent/child luôn có active rõ ràng. -->
							<template #title="{ item }">
								<div class="d-inline-flex align-center ga-1 profile-tree-title" :class="{ 'profile-tree-title--active': String(item.NoiDungID) === String(profileCurrentFolderId || 'profile-root') }" :aria-current="String(item.NoiDungID) === String(profileCurrentFolderId || 'profile-root') ? 'page' : null" @click.stop="openProfileFolderById(item.NoiDungID)">
									<span>{{ item.TenNoiDung }}</span>
									<!-- Badge hiển thị số lượng file: số file trực tiếp trong thư mục, nếu có thêm cây con thì hiển thị dạng [trực tiếp/tổng]. -->
									<span v-if="item.totalFiles > 0" class="profile-tree-count-badge" :title="item.children?.length ? (item.directFiles + ' file trực tiếp · ' + item.totalFiles + ' file toàn bộ nhánh') : (item.directFiles + ' file')">
										{{ item.children?.length && item.totalFiles !== item.directFiles ? (item.directFiles + '/' + item.totalFiles) : item.directFiles }}
									</span>
									<span v-else class="profile-tree-empty-badge" title="Thư mục rỗng">
										0
									</span>
								</div>
							</template>
							<!-- Root chỉ là node hiển thị; người giám sát không được sửa/xóa folder. -->
							<template #append="{ item }">
								<div v-if="item.NoiDungID !== 'profile-root' && !isProfileInspectionMode" class="d-flex align-center ga-1">
									<v-btn icon size="x-small" variant="text" color="primary" @click.stop="openEditProfileFolder(item)"><v-icon size="small">mdi-pencil-outline</v-icon><v-tooltip activator="parent" location="top">Đổi tên thư mục</v-tooltip></v-btn>
									<v-btn icon size="x-small" variant="text" color="error" :loading="deletingDocumentId === item.NoiDungID" :disabled="Boolean(deletingDocumentId)" @click.stop="deleteProfileNode(item)"><v-icon size="small">mdi-delete-outline</v-icon><v-tooltip activator="parent" location="top">Xóa thư mục</v-tooltip></v-btn>
								</div>
							</template>
						</v-treeview>
					</div>
					<div v-if="(innovationLoading && activeBranch === 'initiative') || profileLoading" class="content-hub-empty-state">
						<v-progress-circular indeterminate color="primary" size="32" class="mb-3" />
						<div class="text-body-2 text-medium-emphasis">{{ activeBranch === 'profile' ? 'Đang tải Hồ sơ...' : 'Đang tải tài liệu Sáng kiến...' }}</div>
					</div>
					<!-- Bảng chỉ liệt kê file trực tiếp; khi còn folder con thì hướng dẫn mở folder thay vì báo kho trống. -->
					<div v-else-if="!documentItems.length && activeBranch === 'profile' && profileFolderItems.length" class="content-hub-empty-state">
						<v-icon size="52" class="mb-3 text-medium-emphasis">mdi-folder-open-outline</v-icon>
						<div class="text-body-1 font-weight-medium">Thư mục này chưa có file trực tiếp</div>
						<div class="text-body-2 text-medium-emphasis mt-1">Chọn một thư mục phía trên để xem các file bên trong.</div>
					</div>
					<div v-else-if="!documentItems.length" class="content-hub-empty-state">
						<v-icon size="52" class="mb-3 text-medium-emphasis">mdi-file-document-off-outline</v-icon>
						<div class="text-body-1 font-weight-medium">Chưa có tài liệu</div>
						<div class="text-body-2 text-medium-emphasis mt-1">{{ emptyDocumentMessage }}</div>
					</div>
					<GlobalDataTable v-else :headers="documentHeaders" :items="documentItems" item-value="NoiDungID" items-per-page="-1" hide-default-footer hover :vDataTableHeight="'calc(100dvh - 190px)'">
						<template #item.displayName="{ item }">
							<div class="d-flex align-center ga-2">
								<v-icon :color="getFileColor(item)">{{ getFileIcon(item) }}</v-icon>
								<div>
									<div class="d-flex align-center flex-wrap ga-2">
										<div class="font-weight-medium">{{ item.displayName }}</div>
										<!-- Badge tách video có mốc câu hỏi khỏi video thường ngay ở danh sách tài liệu. -->
										<v-chip v-if="isInteractiveVideo(item)" size="x-small" color="deep-purple" variant="tonal" prepend-icon="mdi-timeline-text-outline">Video tương tác</v-chip>
									</div>
									<div v-if="isInteractiveVideo(item)" class="text-caption text-medium-emphasis">
										{{ getInteractiveQuestionCount(item) }} câu hỏi theo mốc thời gian
									</div>
								</div>
							</div>
						</template>
						<template #item.sourceLabel="{ item }"><v-chip size="small" variant="tonal">{{ item.sourceLabel }}</v-chip></template>
						<!-- Gộp người tạo và thời gian tạo thành 1 cột (2 dòng) để tiết kiệm không gian bảng tài liệu. -->
						<template #item.createdInfo="{ item }">
							<div class="d-flex flex-column py-1">
								<span class="text-body-2 font-weight-medium">{{ item.createdByLabel || '—' }}</span>
								<span v-if="item.createdAtLabel" class="text-caption text-medium-emphasis">{{ formatDate(item.createdAtLabel) }}</span>
							</div>
						</template>
				<template #item.actions="{ item }">
					<div class="question-actions-cell d-flex align-center justify-center ga-1">
								<!-- Video tương tác mở editor timeline để chỉnh mốc/câu hỏi; các loại video khác vẫn giữ thao tác mở nguồn phát. -->
								<v-btn v-if="activeBranch !== 'initiative' || isInitiativeOwner(item) || isInitiativeInspectionMode" icon size="small" variant="text" color="primary" @click="isInteractiveVideo(item) && !isInitiativeInspectionMode ? openInteractiveVideoEditor(item) : openFile(item)"><v-icon>{{ isInteractiveVideo(item) && !isInitiativeInspectionMode ? 'mdi-pencil-outline' : (isImage(item) ? 'mdi-image-outline' : (isOfficeDoc(item) ? 'mdi-file-document-edit-outline' : (isPdf(item) ? 'mdi-file-eye-outline' : 'mdi-open-in-new'))) }}</v-icon><v-tooltip activator="parent" location="top">{{ isInteractiveVideo(item) && !isInitiativeInspectionMode ? 'Chỉnh sửa video tương tác' : (isImage(item) ? 'Xem ảnh' : (isOfficeDoc(item) ? 'Xem tài liệu Office' : (isPdf(item) ? 'Xem PDF' : 'Mở file'))) }}</v-tooltip></v-btn>
								<v-icon v-else size="small" color="medium-emphasis"><v-tooltip activator="parent" location="top">Chỉ người tải lên mới được xem và xóa</v-tooltip>mdi-lock-outline</v-icon>
								<!-- Chỉ người upload mới được xóa file CONTENT_HUB; file của giáo viên khác vẫn chỉ được xem. -->
								<v-btn v-if="!isProfileInspectionMode && !isInitiativeInspectionMode && isContentHubDocument(item) && isContentOwner(item)" icon size="small" variant="text" color="error" :loading="deletingDocumentId === item.NoiDungID" :disabled="Boolean(deletingDocumentId)" @click="deleteDocument(item)"><v-icon>mdi-delete-outline</v-icon><v-tooltip activator="parent" location="top">Xóa tài liệu khỏi kho</v-tooltip></v-btn>
							</div>
						</template>
					</GlobalDataTable>
				</div>

				<!-- Chỉ áp dụng nhịp padding này cho tab Ngân hàng câu hỏi; tab Tài liệu giữ nguyên layout riêng. -->
				<div v-else class="content-hub-questions">
					<!-- Mobile dùng drawer để panel nhóm không chiếm chiều cao phía trên bảng câu hỏi. -->
					<v-navigation-drawer v-model="groupDrawer" temporary location="right" width="320" class="d-lg-none content-hub-group-drawer">
						<div class="pa-4">
							<div class="question-group-toolbar d-flex align-center ga-2 pb-2">
								<span class="text-subtitle-1 font-weight-bold">Nhóm câu hỏi</span>
								<v-chip size="x-small" color="primary" variant="tonal">{{ DSGroup.length }}</v-chip>
								<v-spacer />
								<v-btn icon size="small" variant="tonal" color="success" aria-label="Tạo nhóm" @click="openAddGroup"><v-icon>mdi-plus</v-icon><v-tooltip activator="parent" location="top">Tạo nhóm</v-tooltip></v-btn>
							</div>
							<v-divider />
							<v-list density="comfortable" nav class="question-group-list px-0 mt-2">
								<v-list-item v-for="group in DSGroup" :key="group.Id" rounded="lg" :active="selectedGroup?.Id === group.Id" color="primary" class="mb-1" @click="selectGroup(group)">
									<v-list-item-title class="text-body-2 font-weight-medium">{{ group.Title }}</v-list-item-title>
									<v-list-item-subtitle>{{ group.Description || 'Nhóm câu hỏi' }}</v-list-item-subtitle>
									<template #append>
										<v-btn icon size="x-small" variant="text" color="primary" @click.stop="openEditGroup(group)"><v-icon size="small">mdi-pencil</v-icon></v-btn>
										<v-btn icon size="x-small" variant="text" color="error" @click.stop="deleteGroup(group)"><v-icon size="small">mdi-delete-outline</v-icon></v-btn>
									</template>
								</v-list-item>
								<div v-if="!DSGroup.length" class="text-caption text-medium-emphasis py-8 text-center">
									<v-icon size="34" class="mb-2">mdi-folder-outline</v-icon>
									<div>Chưa có nhóm câu hỏi</div>
									<v-btn size="small" variant="tonal" color="success" class="mt-3" prepend-icon="mdi-plus" @click="openAddGroup">Tạo nhóm câu hỏi</v-btn>
								</div>
							</v-list>
						</div>
					</v-navigation-drawer>
					<v-row no-gutters class="content-hub-question-row">
						<v-col cols="12" lg="3" class="d-none d-lg-block content-hub-group-panel pa-0">
							<!-- Panel nhóm chỉ giữ vai trò điều hướng; thu gọn trên desktop để ưu tiên không gian cho bảng câu hỏi. -->
							<div class="question-group-content">
							<div class="question-group-toolbar d-flex align-center ga-2 pb-2">
								<span class="text-subtitle-2 font-weight-bold">Nhóm câu hỏi</span>
								<v-chip size="x-small" color="primary" variant="tonal">{{ DSGroup.length }}</v-chip>
								<v-spacer />
								<!-- Dùng nút icon có tooltip để không làm header nhóm chiếm hết chiều ngang của panel hẹp. -->
								<v-btn icon size="small" variant="tonal" color="success" aria-label="Tạo nhóm" @click="openAddGroup"><v-icon>mdi-plus</v-icon><v-tooltip activator="parent" location="top">Tạo nhóm</v-tooltip></v-btn>
							</div>
							<v-divider />
							<v-list density="compact" nav class="question-group-list px-0">
								<v-list-item v-for="group in DSGroup" :key="group.Id" rounded="lg" :active="selectedGroup?.Id === group.Id" color="primary" class="mb-1" @click="selectGroup(group)">
									<v-list-item-title class="text-body-2 font-weight-medium">{{ group.Title }}</v-list-item-title>
									<v-list-item-subtitle>{{ group.Description || 'Nhóm câu hỏi' }}</v-list-item-subtitle>
									<template #append>
										<v-btn icon size="x-small" variant="text" color="primary" @click.stop="openEditGroup(group)"><v-icon size="small">mdi-pencil</v-icon><v-tooltip activator="parent" location="top">Sửa nhóm</v-tooltip></v-btn>
										<v-btn icon size="x-small" variant="text" color="error" @click.stop="deleteGroup(group)"><v-icon size="small">mdi-delete-outline</v-icon><v-tooltip activator="parent" location="top">Xóa nhóm</v-tooltip></v-btn>
									</template>
								</v-list-item>
								<div v-if="!DSGroup.length" class="text-caption text-medium-emphasis py-8 text-center">Chưa có nhóm câu hỏi</div>
							</v-list>
							</div>
						</v-col>

						<v-col cols="12" lg="9" class="content-hub-question-panel pa-0">
							<div class="question-list-content">
							<div class="d-flex align-center ga-2 flex-wrap pb-2">
								<span class="text-subtitle-2 font-weight-bold">{{ selectedGroup?.Title || 'Chưa chọn nhóm câu hỏi' }}</span>
								<v-chip v-if="selectedGroup" size="x-small" color="primary" variant="tonal">{{ filteredDSQuestion.length === DSQuestion.length ? `${DSQuestion.length} câu` : `${filteredDSQuestion.length}/${DSQuestion.length} câu` }}</v-chip>
								<!-- Nút xóa hàng loạt khi có câu hỏi được checkbox chọn -->
								<v-btn v-if="selectedQuestions.length" size="small" color="error" variant="flat" prepend-icon="mdi-delete" :loading="deletingMultipleQuestions" @click="deleteSelectedQuestions">
									Xóa {{ selectedQuestions.length }} câu đã chọn
								</v-btn>
								<v-spacer />
								<!-- Lọc câu hỏi theo nguồn file/nguồn import -->
								<v-select
									v-model="selectedQuestionSource"
									:items="questionSourceOptions"
									item-title="label"
									item-value="value"
									density="compact"
									hide-details
									variant="outlined"
									class="question-source-filter"
									style="max-width: 250px; min-width: 170px;"
									:disabled="!selectedGroup || !DSQuestion.length"
									prepend-inner-icon="mdi-filter-variant"
								/>
								<!-- Tìm kiếm server-side có debounce để vừa phản hồi khi nhập vừa tránh gọi API theo từng phím. -->
								<v-text-field v-model="searchQ" placeholder="Tìm câu hỏi..." density="compact" hide-details clearable class="question-search-field" :disabled="!selectedGroup" @update:model-value="onQuestionSearchInput" @keyup.enter="applyQuestionSearch" @click:clear="onClearSearch" />
								<!-- Gom các thao tác tạo/import vào menu để tiết kiệm chiều ngang trên desktop và mobile. -->
								<!-- Import từ file vẫn phải nhìn thấy với giáo viên; chỉ kiểm tra nhóm khi người dùng thực hiện thao tác. -->
								<v-menu location="bottom end">
									<template #activator="{ props }">
										<!-- Truyền icon bằng slot để runtime Vuetify hiện đúng biểu tượng, thay vì phụ thuộc vào prop icon dạng chuỗi. -->
										<v-btn v-bind="props" size="small" variant="tonal" color="primary" icon aria-label="Thao tác câu hỏi"><v-icon>mdi-dots-vertical</v-icon><v-tooltip activator="parent" location="top">Thao tác câu hỏi</v-tooltip></v-btn>
									</template>
					<v-list density="compact" min-width="220">
						<v-list-item prepend-icon="mdi-file-upload-outline" title="Import câu hỏi từ file" :disabled="convertingFile" @click="openQuestionFilePicker" />
						<!-- JSON là luồng quản trị, chỉ SystemRight 9 mới được nhìn thấy. -->
						<v-list-item v-if="canImportQuestionJson" prepend-icon="mdi-code-json" title="Import câu hỏi từ JSON" @click="openImportJsonPicker" />
						<v-list-item prepend-icon="mdi-plus" title="Tạo câu hỏi" @click="openAddQuestion" />
					</v-list>
								</v-menu>
								<input ref="questionFileInput" type="file" accept=".doc,.docx,.pdf,.txt,.html,.htm" class="d-none" @change="convertQuestionFile">
							</div>
							<!-- Import file gọi AI và tạo nhiều bản ghi tuần tự; hiển thị tiến trình ngay tại danh sách để người dùng không tưởng là thao tác bị treo. -->
							<v-progress-linear v-if="convertingFile" indeterminate color="primary" class="mb-2" />
							<div v-if="convertingFile" class="d-flex align-center ga-2 text-caption text-primary mb-2">
								<v-progress-circular indeterminate size="16" width="2" />
								<span>Đang đọc và chuyển {{ convertingFileName || 'file' }} thành câu hỏi...</span>
							</div>
							<v-divider />
							<!-- Dùng GlobalDataTable đồng bộ với tab Tài liệu, hỗ trợ checkbox chọn nhiều câu hỏi để xóa hàng loạt -->
			<div v-if="!selectedGroup" class="content-hub-empty-state question-empty-state">
				<v-icon size="52" class="mb-3 text-medium-emphasis">mdi-folder-plus-outline</v-icon>
				<div class="text-body-1 font-weight-medium">Hãy tạo và chọn nhóm câu hỏi</div>
				<div class="text-body-2 text-medium-emphasis mt-1">Cần có nhóm câu hỏi trước khi tạo, import hoặc quản lý câu hỏi.</div>
				<v-btn size="small" color="success" variant="tonal" prepend-icon="mdi-plus" class="mt-3" @click="openAddGroup">Tạo nhóm câu hỏi</v-btn>
			</div>
			<!-- Khi đổi nhóm, xóa dữ liệu cũ ngay để không nhìn nhầm câu hỏi của group trước; skeleton giữ đúng cảm giác đang tải table mới. -->
			<div v-else-if="questionsLoading && !DSQuestion.length" class="question-table-loading">
				<v-progress-linear indeterminate color="primary" class="mb-3" />
				<div class="d-flex align-center ga-2 text-body-2 font-weight-medium mb-3"><v-progress-circular indeterminate color="primary" size="20" width="2" />Đang tải câu hỏi của nhóm {{ selectedGroup?.Title || '' }}...</div>
				<v-skeleton-loader type="table-heading, table-row@5" class="border rounded" />
			</div>
			<!-- Chỉ dùng empty state này khi bộ taxonomy chưa tải được; nếu đã có các mức độ thì table vẫn phải hiện để user import/tạo ngay cả khi 0 câu. -->
			<div v-else-if="!DSQuestion.length && !DSSkill.length" class="content-hub-empty-state question-empty-state">
				<v-icon size="52" class="mb-3 text-medium-emphasis">mdi-help-circle-outline</v-icon>
				<div class="text-body-1 font-weight-medium">Chưa có câu hỏi</div>
				<div class="text-body-2 text-medium-emphasis mt-1">Tạo mới hoặc import câu hỏi để bắt đầu.</div>
			</div>
			<div v-else-if="DSQuestion.length && !filteredDSQuestion.length" class="content-hub-empty-state question-empty-state">
				<v-icon size="52" class="mb-3 text-medium-emphasis">mdi-filter-off-outline</v-icon>
				<div class="text-body-1 font-weight-medium">Không tìm thấy câu hỏi với nguồn đã chọn</div>
				<div class="text-body-2 text-medium-emphasis mt-1">Hãy chọn lại "Tất cả nguồn" hoặc kiểm tra nguồn file khác.</div>
				<v-btn size="small" color="primary" variant="tonal" class="mt-3" @click="selectedQuestionSource = 'ALL'">Xem tất cả nguồn</v-btn>
			</div>
			<!-- Bảng tùy biến giữ các mức độ theo từng môn ngay trong vùng danh sách câu hỏi; mỗi dòng nhóm là một điểm vào import/tạo mới. -->
			<v-table v-else ref="questionTableRef" density="compact" fixed-header class="content-hub-question-table" height="calc(100dvh - 240px)" style="height: calc(100dvh - 240px); max-height: calc(100dvh - 240px); min-height: 0;">
				<thead>
					<tr>
						<th class="question-select-column">
							<v-checkbox-btn :model-value="allVisibleQuestionsSelected" :indeterminate="someVisibleQuestionsSelected && !allVisibleQuestionsSelected" density="compact" color="primary" aria-label="Chọn tất cả câu hỏi" @update:model-value="toggleAllQuestionSelection" />
						</th>
						<th class="text-center question-index-column">STT</th>
						<th class="question-content-column">Nội dung câu hỏi</th>
						<th class="question-source-column">Nguồn file</th>
						<th class="question-type-column">Loại câu hỏi</th>
						<!-- Tiểu học không còn dùng taxonomy mức độ; các cấp khác vẫn giữ cột này. -->
						<th v-if="!isPrimarySchoolContext" class="question-skill-column">Mức độ</th>
						<th class="question-points-column">Điểm</th>
						<th class="text-center question-actions-column">Thao tác</th>
					</tr>
				</thead>
				<tbody>
				<!-- Cấp còn dùng taxonomy luôn render đủ các mức độ kể cả 0 câu; Tiểu học dùng danh sách phẳng. -->
					<template v-for="level in questionTableGroups" :key="level._key">
						<!-- Với Tiểu học, questionTableGroups chỉ là một nhóm kỹ thuật và không render hàng mức độ. -->
						<tr v-if="!isPrimarySchoolContext" class="question-level-group-row" :class="{ 'cursor-pointer': level.questions.length }" @click="toggleQuestionLevel(level)">
							<td class="question-select-column question-level-select-cell">
								<!-- Tách checkbox thành đúng cột chọn đầu tiên để nội dung group không bị đẩy lệch bởi ô colspan. -->
								<v-checkbox-btn :model-value="isQuestionGroupFullySelected(level)" :indeterminate="isQuestionGroupPartiallySelected(level)" :disabled="!level.questions.length" density="compact" color="primary" :aria-label="`Chọn tất cả câu hỏi mức độ ${level.TenKyNang}`" @click.stop @update:model-value="toggleQuestionGroupSelection(level, $event)" />
							</td>
							<td :colspan="questionHeaders.length" class="py-2 question-level-content-cell">
								<div class="d-flex align-center ga-2">
									<v-icon size="18" color="indigo">{{ isQuestionLevelExpanded(level) ? 'mdi-chevron-down' : 'mdi-chevron-right' }}</v-icon>
									<v-icon size="17" color="indigo">{{ level._isUnassigned ? 'mdi-tag-off-outline' : 'mdi-chart-timeline-variant' }}</v-icon>
									<span class="text-body-2 font-weight-bold text-indigo-darken-2">Mức độ: {{ level.TenKyNang }}</span>
									<v-chip size="x-small" color="indigo" variant="tonal">{{ level.questions.length }} câu</v-chip>
									<v-spacer />
									<!-- Import từ file và Tạo câu hỏi dùng chung cho mọi mức, kể cả nhóm chưa xác định; không gắn v-if/quyền cho luồng file. -->
									<v-btn size="x-small" variant="text" color="primary" prepend-icon="mdi-file-upload-outline" @click.stop="openQuestionFilePicker(level)">Import từ file</v-btn>
									<v-btn v-if="canImportQuestionJson" size="x-small" variant="text" color="purple" prepend-icon="mdi-code-json" @click.stop="openImportJsonPicker(level)">Import từ JSON</v-btn>
									<v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click.stop="openAddQuestion(level)">Tạo câu hỏi</v-btn>
								</div>
							</td>
						</tr>
						<template v-if="isQuestionLevelExpanded(level)">
							<tr v-for="question in level.questions" :key="question.Id || question.ID || question.id" class="question-data-row" :class="getQuestionRowClass(question)" :style="getQuestionRowStyle(question)">
								<td class="text-center question-select-column">
									<v-checkbox-btn :model-value="isQuestionSelected(question)" density="compact" color="primary" :aria-label="`Chọn câu hỏi ${getQuestionTableIndex(question)}`" @click.stop @update:model-value="toggleQuestionSelection(question, $event)" />
								</td>
								<td class="text-center question-index-column"><span class="text-caption font-weight-medium text-medium-emphasis">{{ getQuestionTableIndex(question) }}</span></td>
								<td class="question-content-column">
									<div class="py-2">
										<div class="question-list-title mb-1">
											<!-- Câu hỏi có thể chứa thẻ HTML nguyên văn (đặc biệt khi import môn Tin học); hiển thị thẻ như chữ để không bị trình duyệt thực thi. -->
											<uc-latex-view :content="getQuestionDisplayContent(getQuestionText(question)) || 'Chưa có nội dung câu hỏi'" :literal-html-tags="isComputerSubjectContext" />
										</div>
										<!-- Đáp án cũng là dữ liệu do người dùng/import cung cấp; không được biến thẻ HTML thành markup khi xem nhanh. -->
										<div v-if="getQuestionAnswerItems(question).length" class="question-answer-preview mt-2">
											<div v-for="(answer, answerIndex) in getQuestionAnswerItems(question)" :key="answerIndex" class="question-answer-row">
												<div class="question-answer-label">{{ answer.label }}:</div>
												<div class="question-answer-value"><uc-latex-view :content="getQuestionDisplayContent(answer.text || '—')" :literal-html-tags="isComputerSubjectContext" /></div>
											</div>
										</div>
										<!-- Cảnh báo câu hỏi tự động chấm chưa có đáp án đúng để giáo viên xử lý ngay tại bảng. -->
										<div v-else-if="isQuestionMissingAnswer(question)" class="question-no-answer-warning mt-2 d-flex align-center ga-1">
											<v-icon size="14" color="warning">mdi-alert-circle-outline</v-icon>
											<span class="text-caption font-weight-medium text-warning">Chưa có đáp án đúng — Cần bổ sung đáp án</span>
										</div>
									</div>
								</td>
								<td class="question-source-column"><div class="question-source-file" :title="getQuestionSourceFile(question)"><v-icon size="15" class="mr-1">mdi-file-document-outline</v-icon><span>{{ getQuestionSourceFile(question) }}</span></div></td>
								<td class="question-type-column"><div class="d-flex flex-column ga-1"><v-chip size="small" variant="tonal" color="primary" class="question-type-chip">{{ getTypeLabel(question.Type) }}</v-chip><span v-if="hasQuestionMedia(question)" class="question-media-badge text-caption text-primary"><v-icon size="13" class="mr-1">mdi-paperclip</v-icon>Có media</span></div></td>
								<td v-if="!isPrimarySchoolContext" class="question-skill-column"><div v-if="getQuestionSkills(question).length" class="d-flex flex-wrap ga-1 py-1"><v-chip v-for="skill in getQuestionSkills(question)" :key="skill.KyNang_MonHoc_ChiTietID || skill.SkillCode || skill.id || skill.TenKyNang" size="x-small" variant="tonal" color="indigo">{{ skill.TenKyNang || skill.name }}</v-chip></div><span v-else class="text-caption text-medium-emphasis">—</span></td>
								<td class="question-points-column"><v-chip size="x-small" variant="flat" color="grey-lighten-3" class="font-weight-medium">{{ question.Points || 0 }} đ</v-chip></td>
								<td class="text-center question-actions-column"><div class="d-flex align-center justify-center ga-1"><v-btn icon size="small" variant="text" color="primary" @click.stop="openEditQuestion(question)"><v-icon size="small">mdi-pencil</v-icon><v-tooltip activator="parent" location="top">Sửa câu hỏi</v-tooltip></v-btn><v-btn icon size="small" variant="text" color="error" @click.stop="deleteQuestion(question)"><v-icon size="small">mdi-delete-outline</v-icon><v-tooltip activator="parent" location="top">Xóa câu hỏi</v-tooltip></v-btn></div></td>
			</tr>
						</template>
					</template>
				</tbody>
			</v-table>
							</div>
						</v-col>
					</v-row>
				</div>
			</v-col>
			</v-row>

			<!-- CRUD nguồn câu hỏi dùng đúng các SP Question Bank hiện có; không tạo payload/bảng quản trị mới. -->
			<uc-dialog v-model="dialogGroup" :title="groupForm.Id ? 'Sửa nhóm câu hỏi' : 'Tạo nhóm câu hỏi'" width="560">
				<!-- Các field trong dialog dùng cùng nhịp mb-3 để label, ô nhập và khoảng cách giữa các khối không bị dính nhau. -->
				<v-text-field v-model="groupForm.Title" label="Tên nhóm *" variant="outlined" density="compact" hide-details class="mb-3" />
				<v-textarea v-model="groupForm.Description" label="Mô tả" variant="outlined" density="compact" rows="2" hide-details class="mb-3" />
				<v-text-field v-model.number="groupForm.OrdinalNumber" label="Thứ tự" type="number" variant="outlined" density="compact" hide-details />
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="dialogGroup = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" :loading="savingGroup" @click="saveGroup">Lưu</v-btn>
				</template>
			</uc-dialog>

			<!-- Chuyển dialog Tạo/Sửa câu hỏi sang uc-dialog chuẩn; hỗ trợ giao diện nhập đáp án trực quan cho trắc nghiệm, đúng/sai, điền chỗ trống, nối đáp án. -->
			<uc-dialog v-model="dialogQuestion" :title="questionForm.Id ? 'Sửa câu hỏi' : 'Tạo câu hỏi'" width="760">
				<div class="content-hub-question-dialog">
				<!-- Hàng loại/điểm và nội dung câu hỏi phải tách cùng một nhịp với phần đáp án để form dễ quét. -->
				<v-select v-model="questionForm.GroupId" :items="DSGroup" item-title="Title" item-value="Id" label="Nhóm câu hỏi (không bắt buộc)" variant="outlined" density="compact" clearable hide-details class="mb-3" />
				<v-row dense class="mb-3">
					<v-col cols="6"><v-select v-model="questionForm.Type" :items="TypeOptions" item-title="label" item-value="value" label="Loại câu hỏi *" variant="outlined" density="compact" hide-details @update:modelValue="onQuestionTypeChange" /></v-col>
					<!-- type="number" bị trình duyệt đổi dấu thập phân theo locale (0.25 thành 0,25); Tin học dùng text để giữ đúng dấu chấm khi hiển thị. -->
					<v-col cols="3"><v-text-field v-model="questionForm.Points" label="Điểm" :type="isComputerSubjectContext ? 'text' : 'number'" inputmode="decimal" min="0" :step="isComputerSubjectContext ? 0.25 : 0.5" variant="outlined" density="compact" hide-details /></v-col>
					<!-- Đồng bộ với Soạn bài tập: chỉ câu hỏi QUIZ cho phép đổi cách chấm; câu tự luận/nộp file/ghi âm luôn chấm thủ công. -->
					<v-col cols="3"><v-select v-model="questionForm.GradingType" :items="gradingTypeOptions" label="Cách chấm" item-title="title" item-value="value" variant="outlined" density="compact" hide-details :disabled="!isQuestionAutoGradable(questionForm.Type) || questionForm.Type === 'QUIZ_ORDERING'" :clearable="false" /></v-col>
				</v-row>
				<!-- Câu hỏi Tiểu học không còn gán mức độ; không chỉ ẩn label mà còn bỏ mapping khi lưu. -->
				<v-select v-if="!isPrimarySchoolContext" v-model="questionForm._skillIds" :items="DSSkill" item-title="TenKyNang" item-value="KyNang_MonHoc_ChiTietID" label="Mức độ câu hỏi" multiple chips closable-chips :loading="skillsLoading" variant="outlined" density="compact" no-data-text="Chưa có mức độ câu hỏi" class="mb-3">
					<template #item="{ props, item }"><v-list-item v-bind="props" :subtitle="item.raw.NhomKyNang || ''" /></template>
				</v-select>
				<!-- Giữ uc-rich-text-editor cho mọi môn để không mất toolbar, công thức, định dạng và ảnh nhúng; quy tắc escape mã HTML của Tin học áp dụng ở vùng hiển thị bảng. -->
				<uc-rich-text-editor :key="'question-text-' + (questionForm.Id || 'new')" v-model="questionForm.QuestionText" label="Nội dung câu hỏi *" :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="3" auto-grow class="mb-3" />
				<!-- Media nằm trong ConfigJson.media để dùng chung schema với Soạn bài tập; phần trình bày bám theo uc-media của module đó. -->
				<!-- ==================== MEDIA CÂU HỎI (ĐỒNG BỘ GIAO DIỆN VÀ STYLE VỚI UC-MEDIA SOẠN BÀI TẬP) ==================== -->
				<!-- Media là phần bổ trợ của câu hỏi; đặt order sau phần đáp án để mạch Nội dung → Đáp án không bị ngắt. -->
				<v-expansion-panels variant="accordion" class="mb-3 content-hub-media-panel question-media-section">
					<v-expansion-panel>
						<v-expansion-panel-title class="pa-2 text-subtitle-2 font-weight-medium">
							<div class="d-flex align-center ga-2 w-100">
								<span>Media</span>
								<div v-if="hasQuestionFormMedia" class="d-flex align-center ga-1 flex-wrap">
									<v-chip v-if="questionForm._media.sourceYT?.source" size="x-small" color="red" variant="tonal">
										<v-icon start size="13">mdi-video-outline</v-icon>Video
									</v-chip>
									<v-chip v-if="questionForm._media.sourceRecord?.source" size="x-small" color="teal" variant="tonal">
										<v-icon start size="13">mdi-multimedia</v-icon>Audio
									</v-chip>
									<v-chip v-if="questionForm._media.sourceFiles?.file?.length || questionForm._media.sourceFiles?.image?.length" size="x-small" color="blue" variant="tonal">
										<v-icon start size="13">mdi-file</v-icon>{{ (questionForm._media.sourceFiles?.file?.length || 0) + (questionForm._media.sourceFiles?.image?.length || 0) }} file
									</v-chip>
								</div>
							</div>
						</v-expansion-panel-title>
						<v-expansion-panel-text>
							<!-- Tab chọn loại media thiết kế dạng nút lưới 3 cột có viền bo tròn và chỉ báo chấm xanh như Soạn bài tập -->
							<div class="media-type-tabs mt-2" role="tablist">
								<v-btn class="media-type-tab" :class="{ 'media-type-tab--active': questionForm._media.type === 'YOUTUBE' }" variant="text" @click="questionForm._media.type = 'YOUTUBE'">
									<v-icon size="16">mdi-video-outline</v-icon><span>Video</span><i v-if="questionForm._media.sourceYT?.source" class="media-type-dot" />
								</v-btn>
								<v-btn class="media-type-tab" :class="{ 'media-type-tab--active': questionForm._media.type === 'RECORD_AUDIO' }" variant="text" @click="questionForm._media.type = 'RECORD_AUDIO'">
									<v-icon size="16">mdi-music-note-outline</v-icon><span>Audio</span><i v-if="questionForm._media.sourceRecord?.source" class="media-type-dot" />
								</v-btn>
								<v-btn class="media-type-tab" :class="{ 'media-type-tab--active': questionForm._media.type === 'FILE' }" variant="text" @click="questionForm._media.type = 'FILE'">
									<v-icon size="16">mdi-file-outline</v-icon><span>File</span><i v-if="(questionForm._media.sourceFiles?.file?.length || 0) + (questionForm._media.sourceFiles?.image?.length || 0) > 0" class="media-type-dot" />
								</v-btn>
							</div>

							<!-- Media của câu hỏi lấy từ tài liệu đã có trong tab Tài liệu; không upload lại tại dialog này. -->
							<!-- TAB 1: VIDEO (YOUTUBE HOẶC MP4) -->
							<div v-if="questionForm._media.type === 'YOUTUBE'" class="d-flex flex-column ga-2 mt-3">
								<v-autocomplete :items="questionMediaItems" item-title="displayName" return-object clearable label="Chọn video từ tab Tài liệu" no-data-text="Không tìm thấy video" variant="outlined" density="compact" hide-details="auto" @update:modelValue="selectQuestionMedia">
									<template #selection="{ item }">
										<div class="d-flex align-center ga-2 text-truncate">
											<v-icon size="18" :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											<span class="text-truncate">{{ item.raw.displayName }}</span>
											<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal" class="ml-1">{{ getFileTypeLabel(item.raw) }}</v-chip>
											<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">({{ formatDateShort(item.raw.updatedLabel) }})</span>
										</div>
									</template>
									<template #item="{ props, item }">
										<v-list-item v-bind="props" :title="undefined" class="py-2">
											<template #prepend>
												<v-icon :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											</template>
											<v-list-item-title class="font-weight-medium text-truncate">{{ item.raw.displayName }}</v-list-item-title>
											<v-list-item-subtitle class="d-flex flex-wrap align-center ga-2 mt-1">
												<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal">{{ getFileTypeLabel(item.raw) }}</v-chip>
												<span v-if="formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize)" class="text-caption text-medium-emphasis">· {{ formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize) }}</span>
												<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">· {{ formatDate(item.raw.updatedLabel) }}</span>
												<span v-if="item.raw.ownerLabel && item.raw.ownerLabel !== '—'" class="text-caption text-medium-emphasis">· {{ item.raw.ownerLabel }}</span>
												<span v-if="item.raw.sourceLabel" class="text-caption text-medium-emphasis">· [{{ item.raw.sourceLabel }}]</span>
											</v-list-item-subtitle>
										</v-list-item>
									</template>
								</v-autocomplete>
								<div v-if="!questionMediaItems.length" class="text-caption text-medium-emphasis">Chưa có video trong tab Tài liệu để chọn.</div>
								<div v-if="questionForm._media.sourceYT.source" class="assignment-media-video-card">
									<iframe v-if="getQuestionYoutubeEmbedUrl(questionForm._media.sourceYT.source)" :src="getQuestionYoutubeEmbedUrl(questionForm._media.sourceYT.source)" title="YouTube video player" frameborder="0" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" allowfullscreen class="assignment-media-video" />
									<video v-else controls class="assignment-media-video" :src="questionForm._media.sourceYT.source" />
									<div class="media-card-footer">
										<span class="text-caption text-truncate">{{ questionForm._media.sourceYT.name || questionForm._media.sourceYT.source || 'Video' }}</span>
										<v-btn class="media-card-delete" icon="mdi-close" variant="text" size="x-small" title="Bỏ liên kết video khỏi câu hỏi" aria-label="Bỏ liên kết video khỏi câu hỏi" @click.stop="clearQuestionMedia('YOUTUBE')" />
									</div>
								</div>
								<div v-else class="assignment-media-empty">
									<v-icon size="30">mdi-video-off-outline</v-icon>
									<span>Chưa có video</span>
								</div>
							</div>

							<!-- TAB 2: AUDIO -->
							<div v-else-if="questionForm._media.type === 'RECORD_AUDIO'" class="d-flex flex-column ga-2 mt-3">
								<v-autocomplete :items="questionMediaItems" item-title="displayName" return-object clearable label="Chọn audio từ tab Tài liệu" no-data-text="Không tìm thấy audio" variant="outlined" density="compact" hide-details="auto" @update:modelValue="selectQuestionMedia">
									<template #selection="{ item }">
										<div class="d-flex align-center ga-2 text-truncate">
											<v-icon size="18" :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											<span class="text-truncate">{{ item.raw.displayName }}</span>
											<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal" class="ml-1">{{ getFileTypeLabel(item.raw) }}</v-chip>
											<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">({{ formatDateShort(item.raw.updatedLabel) }})</span>
										</div>
									</template>
									<template #item="{ props, item }">
										<v-list-item v-bind="props" :title="undefined" class="py-2">
											<template #prepend>
												<v-icon :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											</template>
											<v-list-item-title class="font-weight-medium text-truncate">{{ item.raw.displayName }}</v-list-item-title>
											<v-list-item-subtitle class="d-flex flex-wrap align-center ga-2 mt-1">
												<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal">{{ getFileTypeLabel(item.raw) }}</v-chip>
												<span v-if="formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize)" class="text-caption text-medium-emphasis">· {{ formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize) }}</span>
												<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">· {{ formatDate(item.raw.updatedLabel) }}</span>
												<span v-if="item.raw.ownerLabel && item.raw.ownerLabel !== '—'" class="text-caption text-medium-emphasis">· {{ item.raw.ownerLabel }}</span>
												<span v-if="item.raw.sourceLabel" class="text-caption text-medium-emphasis">· [{{ item.raw.sourceLabel }}]</span>
											</v-list-item-subtitle>
										</v-list-item>
									</template>
								</v-autocomplete>
								<div v-if="!questionMediaItems.length" class="text-caption text-medium-emphasis">Chưa có audio trong tab Tài liệu để chọn.</div>
								<div v-if="questionForm._media.sourceRecord.source" class="assignment-media-file-card pa-3">
									<!-- Dùng chung audio player với Soạn bài tập; không dùng native audio controls riêng để hai màn hình hiển thị nhất quán. -->
									<uc-wave-audio-player :audioUrl="questionForm._media.sourceRecord.source" />
									<div class="media-card-footer px-0">
										<span class="text-caption text-truncate">{{ questionForm._media.sourceRecord.name || questionForm._media.sourceRecord.source || 'Audio' }}</span>
										<v-btn class="media-card-delete" icon="mdi-close" variant="text" size="x-small" title="Bỏ liên kết audio khỏi câu hỏi" aria-label="Bỏ liên kết audio khỏi câu hỏi" @click.stop="clearQuestionMedia('RECORD_AUDIO')" />
									</div>
								</div>
								<div v-else class="assignment-media-empty">
									<v-icon size="30">mdi-music-note-off</v-icon>
									<span>Chưa có audio</span>
								</div>
							</div>

							<!-- TAB 3: FILE & HÌNH ẢNH -->
							<div v-else class="d-flex flex-column ga-3 mt-3">
								<v-autocomplete :items="questionMediaItems" item-title="displayName" return-object clearable label="Chọn tài liệu từ tab Tài liệu" no-data-text="Không tìm thấy tài liệu" variant="outlined" density="compact" hide-details="auto" @update:modelValue="selectQuestionMedia">
									<template #selection="{ item }">
										<div class="d-flex align-center ga-2 text-truncate">
											<v-icon size="18" :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											<span class="text-truncate">{{ item.raw.displayName }}</span>
											<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal" class="ml-1">{{ getFileTypeLabel(item.raw) }}</v-chip>
											<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">({{ formatDateShort(item.raw.updatedLabel) }})</span>
										</div>
									</template>
									<template #item="{ props, item }">
										<v-list-item v-bind="props" :title="undefined" class="py-2">
											<template #prepend>
												<v-icon :color="getFileColor(item.raw)">{{ getFileIcon(item.raw) }}</v-icon>
											</template>
											<v-list-item-title class="font-weight-medium text-truncate">{{ item.raw.displayName }}</v-list-item-title>
											<v-list-item-subtitle class="d-flex flex-wrap align-center ga-2 mt-1">
												<v-chip size="x-small" :color="getFileColor(item.raw)" variant="tonal">{{ getFileTypeLabel(item.raw) }}</v-chip>
												<span v-if="formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize)" class="text-caption text-medium-emphasis">· {{ formatFileSize(item.raw._meta?.fileSize || item.raw.fileSize) }}</span>
												<span v-if="item.raw.updatedLabel && item.raw.updatedLabel !== '—'" class="text-caption text-medium-emphasis">· {{ formatDate(item.raw.updatedLabel) }}</span>
												<span v-if="item.raw.ownerLabel && item.raw.ownerLabel !== '—'" class="text-caption text-medium-emphasis">· {{ item.raw.ownerLabel }}</span>
												<span v-if="item.raw.sourceLabel" class="text-caption text-medium-emphasis">· [{{ item.raw.sourceLabel }}]</span>
											</v-list-item-subtitle>
										</v-list-item>
									</template>
								</v-autocomplete>
								<div v-if="!questionMediaItems.length" class="text-caption text-medium-emphasis">Chưa có tài liệu trong tab Tài liệu để chọn.</div>

								<!-- Phân nhóm hình ảnh -->
								<div class="text-subtitle-2 font-weight-medium">Hình ảnh</div>
								<div v-if="questionForm._media.sourceFiles.image.length" class="assignment-media-image-grid">
									<div v-for="(file, index) in questionForm._media.sourceFiles.image" :key="file.id || file.source || index" class="assignment-media-image-card">
										<!-- Ảnh phải dùng URL binary của LMS; URL Google Drive /preview là HTML nên v-img sẽ chờ vô hạn. eager giúp thumbnail tải ngay khi card hiển thị. -->
										<v-img :src="getQuestionMediaSource(file, 'image')" :alt="file.name || 'Hình ảnh câu hỏi'" eager cover class="assignment-media-image-preview">
											<template #placeholder><div class="d-flex align-center justify-center fill-height"><v-progress-circular indeterminate color="primary" size="20" /></div></template>
											<template #error><div class="assignment-media-image-error"><v-icon size="28" color="grey">mdi-image-broken-variant</v-icon><span class="text-caption">Không tải được ảnh</span></div></template>
										</v-img>
										<div class="media-card-footer">
											<span class="text-caption text-truncate">{{ file.name || file.source }}</span>
											<v-btn class="media-card-delete" icon="mdi-close" variant="text" size="x-small" title="Bỏ liên kết ảnh khỏi câu hỏi" aria-label="Bỏ liên kết ảnh khỏi câu hỏi" @click.stop="removeQuestionMediaFile('image', index)" />
										</div>
									</div>
								</div>
								<div v-else class="assignment-media-empty">
									<v-icon size="30">mdi-image-off-outline</v-icon>
									<span>Chưa có hình ảnh</span>
								</div>

								<!-- Phân nhóm tệp đính kèm -->
								<div class="text-subtitle-2 font-weight-medium">Tệp đính kèm</div>
								<div v-if="questionForm._media.sourceFiles.file.length" class="assignment-media-file-list">
									<div v-for="(file, index) in questionForm._media.sourceFiles.file" :key="file.id || file.source || index" class="assignment-media-file-card">
										<div class="assignment-media-file-fallback">
											<v-icon color="primary" size="24">mdi-file-outline</v-icon>
											<a :href="getQuestionMediaSource(file)" target="_blank" rel="noopener" class="text-truncate text-body-2 font-weight-medium text-decoration-none text-primary">{{ file.name || file.source }}</a>
											<v-btn :href="getQuestionMediaSource(file)" target="_blank" rel="noopener" icon="mdi-open-in-new" variant="tonal" size="x-small" color="primary" title="Mở file" />
										</div>
										<div class="media-card-footer">
											<span class="text-caption text-truncate">{{ file.name || file.source }}</span>
											<v-btn class="media-card-delete" icon="mdi-close" variant="text" size="x-small" title="Bỏ liên kết tệp khỏi câu hỏi" aria-label="Bỏ liên kết tệp khỏi câu hỏi" @click.stop="removeQuestionMediaFile('file', index)" />
										</div>
									</div>
								</div>
								<div v-else class="assignment-media-empty">
									<v-icon size="30">mdi-file-outline</v-icon>
									<span>Chưa có tệp đính kèm</span>
								</div>
							</div>
						</v-expansion-panel-text>
					</v-expansion-panel>
				</v-expansion-panels>

				<!-- Các nhóm đáp án được gom thành một khối liền mạch; CSS chỉ dùng order để media hiển thị sau khối này. -->
				<div class="question-answer-section">
				<!-- ==================== ĐÁP ÁN: QUIZ_SINGLE_CHOICE & QUIZ_MULTIPLE_CHOICE ==================== -->
				<template v-if="questionForm.Type === 'QUIZ_SINGLE_CHOICE' || questionForm.Type === 'QUIZ_MULTIPLE_CHOICE'">
					<div class="d-flex align-center justify-space-between mb-2">
						<div class="text-subtitle-2 font-weight-bold">Đáp án</div>
						<!-- Chế độ nâng cao dùng rich-text cho đáp án, còn chế độ thường giữ input gọn. -->
						<v-checkbox v-model="questionForm._isAdvanced" label="Nâng cao" color="warning" hide-details density="compact" />
					</div>
					<!-- BẮT BUỘC: Vuetify 3 yêu cầu v-radio phải nằm trong v-radio-group để đồng bộ nhóm, tránh lỗi chọn được nhiều đáp án khi tạo/sửa câu hỏi trắc nghiệm 1 đáp án (QUIZ_SINGLE_CHOICE). -->
					<v-radio-group v-if="questionForm.Type === 'QUIZ_SINGLE_CHOICE'" v-model="questionForm._correctIndex" hide-details class="ma-0 pa-0">
						<v-row v-for="(option, index) in questionForm._options" :key="index" dense align="center" class="question-option-row mb-2">
							<v-col cols="1" class="d-flex align-center justify-center">
								<v-radio :value="index" hide-details />
							</v-col>
							<v-col cols="10">
								<!-- Tin học luôn dùng input text cho đáp án để mã HTML/comment không bị uc-latex-edit diễn giải; môn khác mới dùng editor nâng cao. -->
								<uc-latex-edit v-if="questionForm._isAdvanced && !isComputerSubjectContext" v-model:content="questionForm._options[index]" class="w-100" />
								<v-text-field v-else v-model="questionForm._plainOptions[index]" :label="'Đáp án ' + (index + 1)" variant="outlined" density="compact" hide-details @update:modelValue="questionForm._options[index] = $event" />
							</v-col>
							<v-col cols="1" class="d-flex align-center justify-center">
								<v-btn v-if="questionForm._options.length > 2" icon size="x-small" variant="text" color="error" @click="removeQuestionOption(index)"><v-icon>mdi-close</v-icon></v-btn>
							</v-col>
						</v-row>
					</v-radio-group>
					<!-- Trắc nghiệm nhiều đáp án dùng checkbox độc lập cho từng lựa chọn -->
					<template v-else-if="questionForm.Type === 'QUIZ_MULTIPLE_CHOICE'">
						<v-row v-for="(option, index) in questionForm._options" :key="index" dense align="center" class="question-option-row mb-2">
							<v-col cols="1" class="d-flex align-center justify-center">
								<v-checkbox v-model="questionForm._correctIndexes" :value="index" hide-details density="compact" />
							</v-col>
							<v-col cols="10">
								<!-- Cùng quy tắc với trắc nghiệm một đáp án: Tin học phải giữ literal HTML/comment trong input, không để editor render hoặc ẩn mã. -->
								<uc-latex-edit v-if="questionForm._isAdvanced && !isComputerSubjectContext" v-model:content="questionForm._options[index]" class="w-100" />
								<v-text-field v-else v-model="questionForm._plainOptions[index]" :label="'Đáp án ' + (index + 1)" variant="outlined" density="compact" hide-details @update:modelValue="questionForm._options[index] = $event" />
							</v-col>
							<v-col cols="1" class="d-flex align-center justify-center">
								<v-btn v-if="questionForm._options.length > 2" icon size="x-small" variant="text" color="error" @click="removeQuestionOption(index)"><v-icon>mdi-close</v-icon></v-btn>
							</v-col>
						</v-row>
					</template>
					<!-- Hai mảng được thêm đồng thời vì fallback editor bind vào _plainOptions, còn rich editor bind vào _options. -->
					<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="questionForm._options.push(''); questionForm._plainOptions.push('')">Thêm đáp án</v-btn>
				</template>

				<!-- ==================== ĐÁP ÁN: QUIZ_TRUE_FALSE (Đúng / Sai) ==================== -->
				<template v-else-if="questionForm.Type === 'QUIZ_TRUE_FALSE'">
					<!-- Nếu có danh sách mệnh đề dạng options thì hiển thị theo từng mệnh đề; nếu chỉ 1 câu hỏi thì hiển thị radio Đúng / Sai -->
					<div v-if="questionForm._tfOptions && questionForm._tfOptions.length" class="mb-3">
						<div class="text-subtitle-2 font-weight-bold mb-2">Các mệnh đề và đáp án Đúng / Sai</div>
						<div v-for="(opt, i) in questionForm._tfOptions" :key="i" class="d-flex align-center ga-2 mb-2">
							<div class="d-flex align-center ga-1" style="min-width: 140px;">
								<v-btn size="small" :variant="opt.correctAnswer ? 'flat' : 'outlined'" color="success" class="text-none px-2" @click="opt.correctAnswer = true; opt.inCorrectAnswer = false">Đúng</v-btn>
								<v-btn size="small" :variant="opt.inCorrectAnswer ? 'flat' : 'outlined'" color="error" class="text-none px-2" @click="opt.inCorrectAnswer = true; opt.correctAnswer = false">Sai</v-btn>
							</div>
							<v-text-field v-model="opt.text" variant="outlined" density="compact" hide-details placeholder="Nội dung mệnh đề..." class="flex-grow-1" />
							<v-btn v-if="questionForm._tfOptions.length > 1" icon size="x-small" variant="text" color="error" @click="questionForm._tfOptions.splice(i, 1)"><v-icon>mdi-close</v-icon></v-btn>
						</div>
						<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="questionForm._tfOptions.push({ text: '', correctAnswer: true, inCorrectAnswer: false })">Thêm mệnh đề</v-btn>
					</div>
					<div v-else class="mb-3">
						<div class="text-subtitle-2 font-weight-bold mb-2">Đáp án đúng</div>
						<v-radio-group v-model="questionForm._tfAnswer" inline hide-details>
							<v-radio :value="true" label="Đúng" color="success" />
							<v-radio :value="false" label="Sai" color="error" class="ml-6" />
						</v-radio-group>
					</div>
				</template>

				<!-- ==================== ĐÁP ÁN: QUIZ_MULTIPLE_TRUE_FALSE (Nhiều mệnh đề Đúng / Sai) ==================== -->
				<template v-else-if="questionForm.Type === 'QUIZ_MULTIPLE_TRUE_FALSE'">
					<div class="text-subtitle-2 font-weight-bold mb-2">Các mệnh đề Đúng / Sai</div>
					<!-- Có đúng 4 mệnh đề thì tự động dùng cách tính điểm theo từng ý giống Soạn bài tập. -->
					<v-select v-model="questionForm._tfScoringMode" :items="[
						{ value: 'equal', title: 'Tính điểm cho cả câu' },
						{ value: 'partial', title: 'Tính điểm theo từng ý' }
					]" label="Cách tính điểm" variant="outlined" density="compact" hide-details class="mb-2" :disabled="questionForm._tfOptions.length === 4" @update:modelValue="onMultipleTrueFalseScoringModeChange" />
					<v-alert v-if="questionForm._tfOptions.length === 4" density="compact" variant="tonal" color="info" class="mb-3">Đã có 4 mệnh đề, hệ thống tự động tính điểm theo từng ý.</v-alert>
					<v-row v-for="(opt, i) in questionForm._tfOptions" :key="i" dense align="center" class="mb-2">
						<v-col cols="12" md="3" class="d-flex align-center ga-1">
							<v-btn size="small" :variant="opt.correctAnswer ? 'flat' : 'outlined'" color="success" class="text-none px-2" @click="opt.correctAnswer = true; opt.inCorrectAnswer = false">Đúng</v-btn>
							<v-btn size="small" :variant="opt.inCorrectAnswer ? 'flat' : 'outlined'" color="error" class="text-none px-2" @click="opt.inCorrectAnswer = true; opt.correctAnswer = false">Sai</v-btn>
						</v-col>
						<v-col cols="10" md="8"><v-text-field v-model="opt.text" variant="outlined" density="compact" hide-details placeholder="Nhập mệnh đề..." /></v-col>
						<v-col cols="2" md="1" class="d-flex justify-center"><v-btn v-if="questionForm._tfOptions.length > 2 && questionForm._tfOptions.length !== 4" icon size="x-small" variant="text" color="error" @click="removeMultipleTrueFalseStatement(i)"><v-icon>mdi-close</v-icon></v-btn></v-col>
					</v-row>
					<v-btn v-if="questionForm._tfOptions.length !== 4" size="small" variant="tonal" prepend-icon="mdi-plus" @click="addMultipleTrueFalseStatement">Thêm mệnh đề</v-btn>
				</template>

				<!-- ==================== ĐÁP ÁN: QUIZ_FILL_IN_BLANK (Điền chỗ trống) ==================== -->
				<template v-else-if="questionForm.Type === 'QUIZ_FILL_IN_BLANK'">
					<!-- Mỗi ô trống hiển thị các đáp án chấp nhận được bằng chip, giống Soạn bài tập; không gộp thành một chuỗi khó chỉnh sửa. -->
					<div class="text-subtitle-2 font-weight-bold mb-2">Đáp án</div>
					<div v-for="(part, i) in questionForm._blankParts" :key="i" class="d-flex align-start ga-2 mb-2">
						<v-chip size="x-small" variant="tonal" :color="part.type === 'blank' ? 'indigo' : 'default'" class="mt-3 flex-shrink-0" style="min-width: 68px; justify-content: center;">
							{{ part.type === 'blank' ? 'Chỗ trống' : 'Văn bản' }}
						</v-chip>
						<v-text-field v-if="part.type === 'text'" v-model="part.value" variant="outlined" density="compact" hide-details :clearable="false" class="flex-grow-1" placeholder="Nhập văn bản..." />
						<div v-else class="flex-grow-1 rounded pa-2" style="border: 1.5px dashed rgba(0,0,0,0.3);">
							<div v-if="part.acceptedAnswers && part.acceptedAnswers.length" class="d-flex flex-wrap ga-1 mb-2">
								<v-chip v-for="(ans, ai) in part.acceptedAnswers" :key="ai" size="small" color="success" variant="tonal" closable @click:close="part.acceptedAnswers.splice(ai, 1)">
									{{ ans }}
								</v-chip>
							</div>
							<p v-else class="text-caption text-medium-emphasis mb-2">Chưa có đáp án — nhập và Enter để thêm</p>
							<v-text-field v-model="blankInputs[i]" placeholder="Nhập đáp án rồi Enter..." variant="outlined" density="compact" hide-details :clearable="false" append-inner-icon="mdi-keyboard-return" @keydown.enter.prevent="addBlankAnswer(part, i)" />
						</div>
						<v-btn icon size="small" variant="text" color="error" class="mt-1" @click="removeQuestionBlankPart(i)">
							<v-icon>mdi-close</v-icon>
						</v-btn>
					</div>
					<div class="d-flex ga-2 mt-2">
						<v-btn size="small" variant="tonal" prepend-icon="mdi-format-text" @click="addQuestionBlankPart('text')">Văn bản</v-btn>
						<v-btn size="small" variant="tonal" color="indigo" prepend-icon="mdi-form-textbox" @click="addQuestionBlankPart('blank')">Chỗ trống</v-btn>
					</div>
				</template>

				<!-- ==================== ĐÁP ÁN: QUIZ_MATCHING (Nối cặp đáp án) ==================== -->
				<template v-else-if="questionForm.Type === 'QUIZ_MATCHING'">
					<div class="text-subtitle-2 font-weight-bold mb-2">Các cặp ghép nối (Cột A → Cột B)</div>
					<v-row v-for="(pair, i) in questionForm._matchingPairs" :key="i" dense class="mb-2" align="center">
						<v-col cols="5"><v-text-field v-model="pair.left" label="Cột A" variant="outlined" density="compact" hide-details placeholder="Ý ở cột A..." /></v-col>
						<v-col cols="1" class="text-center"><v-icon color="medium-emphasis">mdi-arrow-right</v-icon></v-col>
						<v-col cols="5"><v-text-field v-model="pair.right" label="Cột B (nối tương ứng)" variant="outlined" density="compact" hide-details placeholder="Ý ở cột B tương ứng..." /></v-col>
						<v-col cols="1"><v-btn v-if="questionForm._matchingPairs.length > 1" icon size="x-small" variant="text" color="error" @click="questionForm._matchingPairs.splice(i, 1)"><v-icon>mdi-close</v-icon></v-btn></v-col>
					</v-row>
					<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="questionForm._matchingPairs.push({ left: '', right: '' })">Thêm cặp nối</v-btn>
				</template>

				<!-- ==================== ĐÁP ÁN: QUIZ_ORDERING (Sắp xếp thứ tự) ==================== -->
				<template v-else-if="questionForm.Type === 'QUIZ_ORDERING'">
					<div class="text-subtitle-2 font-weight-bold mb-2">Các ý theo thứ tự đúng</div>
					<p class="text-caption text-medium-emphasis mb-2">Thứ tự đang hiển thị là đáp án đúng; học sinh sẽ sắp xếp lại các ý khi làm bài.</p>
					<div v-for="(entry, i) in questionForm._orderingItems" :key="entry.id || i" class="d-flex align-start ga-2 mb-2">
						<v-chip size="small" color="primary" variant="tonal" class="mt-2 flex-shrink-0">{{ i + 1 }}</v-chip>
						<v-text-field v-model="entry.text" label="Nội dung ý" variant="outlined" density="compact" hide-details class="flex-grow-1" />
						<div class="d-flex align-center mt-1">
							<v-btn icon="mdi-arrow-up" size="small" variant="text" :disabled="i === 0" @click="moveQuestionOrderingItem(i, -1)" />
							<v-btn icon="mdi-arrow-down" size="small" variant="text" :disabled="i === questionForm._orderingItems.length - 1" @click="moveQuestionOrderingItem(i, 1)" />
							<v-btn v-if="questionForm._orderingItems.length > 2" icon="mdi-delete-outline" size="small" variant="text" color="error" @click="removeQuestionOrderingItem(i)" />
						</div>
					</div>
					<v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click="addQuestionOrderingItem">Thêm ý</v-btn>
					<p class="text-caption text-medium-emphasis mt-2 mb-0">Chấm đều: mỗi ý đúng vị trí = tổng điểm câu / số ý.</p>
				</template>

				<!-- ==================== CÁC LOẠI CÂU HỎI TỰ LUẬN / CHẤM TAY ==================== -->
				<template v-else-if="['SHORT_ANSWER', 'ESSAY', 'FILE_UPLOAD', 'AUDIO_RESPONSE'].includes(questionForm.Type)">
					<!-- referenceAnswer chỉ dành cho câu chấm tay; đặt tiêu đề ngoài editor vì label của f-editor không nổi bật trong dialog. -->
					<div v-if="['SHORT_ANSWER', 'ESSAY'].includes(questionForm.Type)" class="mb-2">
						<div class="text-subtitle-2 font-weight-medium">Đáp án tham khảo <span class="text-caption text-medium-emphasis">(chỉ giáo viên xem)</span></div>
						<div class="text-caption text-medium-emphasis">Ghi đáp án mẫu hoặc ý chính để giáo viên đối chiếu khi chấm; học sinh không nhìn thấy nội dung này.</div>
					</div>
					<uc-rich-text-editor v-if="['SHORT_ANSWER', 'ESSAY'].includes(questionForm.Type)"
						:key="'reference-answer-' + (questionForm.Id || 'new')"
						v-model="questionForm._referenceAnswer"
						label="Đáp án tham khảo (chỉ giáo viên xem)"
						placeholder="Nhập ý chính hoặc đáp án tham khảo để giáo viên đối chiếu khi chấm..."
						:imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)"
						variant="outlined" rows="4" auto-grow class="mb-2" />
					<v-alert density="compact" variant="tonal" color="info" class="mb-2">Loại câu hỏi này học sinh sẽ làm bài tự luận hoặc nộp tệp / ghi âm; giáo viên sẽ chấm điểm thủ công.</v-alert>
				</template>

				<!-- Loại tùy biến khác -->
				<template v-else-if="questionForm.Type">
					<v-alert density="compact" variant="tonal" color="info" class="mb-3">Loại câu hỏi này dùng cấu hình nâng cao. Có thể nhập JSON cấu hình nếu cần.</v-alert>
					<v-textarea v-model="questionForm.ConfigJson" label="Cấu hình JSON (không bắt buộc)" variant="outlined" density="compact" rows="4" hide-details />
				</template>
				</div>
				</div>

				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="dialogQuestion = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" :loading="savingQuestion" @click="saveQuestion">Lưu</v-btn>
				</template>
			</uc-dialog>

			<!-- Bắt buộc chọn loại trước khi mở luồng upload để metadata tài nguyên phản ánh đúng mục đích sử dụng, thay vì chỉ suy luận từ đuôi tệp. -->
			<uc-dialog v-model="dialogUpload" title="Chọn loại tài liệu" :width="pendingUploadType === 'VIDEO' && uploadVideoMode === 'INTERACTIVE' ? 960 : 680">
				<div class="text-body-2 text-medium-emphasis mb-3">Chọn loại và cách đưa nội dung vào kho.</div>
				<v-row dense>
					<v-col v-for="option in materialTypeOptions" :key="option.value" cols="12" sm="6" md="4">
						<v-card variant="outlined" :class="{ 'upload-type-option--active': pendingUploadType === option.value }" class="upload-type-option h-100" @click="pendingUploadType = option.value">
							<v-card-text class="d-flex align-center ga-3 pa-3">
								<v-icon :color="pendingUploadType === option.value ? 'primary' : 'medium-emphasis'">{{ option.icon }}</v-icon>
								<div><div class="font-weight-medium" :class="{ 'text-primary': pendingUploadType === option.value }">{{ option.title }}</div><div class="text-caption text-medium-emphasis">{{ option.description }}</div></div>
							</v-card-text>
						</v-card>
					</v-col>
				</v-row>
				<!-- Nội dung theo loại được gom vào một panel riêng để dialog có nhịp thị giác rõ: tiêu đề → hướng dẫn → thao tác. -->
				<div v-if="pendingUploadType" class="upload-content-panel mt-4">
					<div class="upload-content-header">
						<div class="upload-content-heading">
							<div class="upload-content-icon"><v-icon size="20" color="primary">{{ selectedMaterialType?.icon }}</v-icon></div>
							<div>
								<div class="text-subtitle-2 font-weight-bold">{{ selectedMaterialType?.title }}</div>
								<div class="text-caption text-medium-emphasis">{{ selectedMaterialType?.description }}</div>
							</div>
						</div>
						<v-chip size="small" color="primary" variant="tonal">Đang chọn</v-chip>
					</div>
					<div class="upload-content-body">
						<div v-if="pendingUploadType === 'VIDEO'" class="upload-content-section">
							<!-- Video thường giữ nguyên luồng cũ; video tương tác có editor timeline riêng giống Soạn học liệu. -->
							<v-btn-toggle v-model="uploadVideoMode" color="primary" mandatory divided class="d-flex flex-wrap w-100 mb-4">
								<v-btn value="STANDARD" prepend-icon="mdi-play-circle-outline" class="flex-grow-1 text-none">Video thường</v-btn>
								<v-btn value="INTERACTIVE" prepend-icon="mdi-timeline-text-outline" class="flex-grow-1 text-none">Video tương tác</v-btn>
							</v-btn-toggle>
			<!-- Mô tả đã có ngay trên thẻ loại tài liệu; không lặp lại bằng alert để form gọn hơn. -->

							<div v-if="uploadVideoMode === 'STANDARD'">
								<!-- Tên video chuẩn hóa để link dán không bị mặc định gán cứng 'Video YouTube' -->
								<div class="upload-section-label"><v-icon size="16">mdi-format-title</v-icon><span>Tên video / Tên tài liệu</span></div>
								<v-text-field v-model="uploadVideoName" placeholder="Nhập tên video..." variant="outlined" density="compact" hide-details="auto" class="mb-3" />
								<div class="upload-section-label"><v-icon size="16">mdi-link-variant</v-icon><span>Dán link YouTube</span></div>
								<v-text-field v-model="uploadVideoUrl" placeholder="https://www.youtube.com/watch?v=..." variant="outlined" density="compact" hide-details="auto" append-inner-icon="mdi-link" @keydown.enter="saveVideoLink" />
								<div class="upload-section-divider"><span>hoặc</span></div>
								<div class="upload-section-label"><v-icon size="16">mdi-video-plus-outline</v-icon><span>Tải video từ máy tính</span></div>
								<v-btn block variant="outlined" color="primary" prepend-icon="mdi-upload" @click="$refs.videoUploadInput?.click()">Tải video lên YouTube</v-btn>
								<input ref="videoUploadInput" type="file" accept="video/*" class="d-none" @change="uploadVideoToYoutube($event.target.files?.[0])" />
							</div>

							<div v-else class="content-hub-interactive-video">
								<!-- Tên video tương tác: cho phép đặt tên bài học rõ ràng hoặc tự động điền tên file khi upload máy tính -->
								<div class="upload-section-label"><v-icon size="16">mdi-format-title</v-icon><span>Tên video / Tên tài liệu tương tác</span></div>
								<v-text-field v-model="interactiveVideoName" placeholder="Nhập tên video / tên bài học tương tác..." variant="outlined" density="compact" hide-details="auto" class="mb-3" />
								<div class="upload-section-label"><v-icon size="16">mdi-link-variant</v-icon><span>Link video YouTube hoặc video trực tiếp</span></div>
								<v-text-field v-model="interactiveVideoUrl" placeholder="https://www.youtube.com/watch?v=..." variant="outlined" density="compact" hide-details="auto" append-inner-icon="mdi-link" @update:modelValue="onInteractiveVideoUrlChange" />
								<div class="upload-section-divider"><span>hoặc</span></div>
								<div class="upload-section-label"><v-icon size="16">mdi-video-plus-outline</v-icon><span>Tải video từ máy tính</span></div>
								<v-file-input accept="video/*" label="Tải video để phát hành lên YouTube" placeholder="Chọn file video" prepend-icon="mdi-upload" variant="outlined" density="compact" hide-details="auto" @update:modelValue="uploadInteractiveVideoToYoutube" />

								<div v-if="interactiveVideoUrl" class="mt-4">
									<div class="content-hub-interactive-player">
										<div v-if="interactiveYoutubeVideoId" ref="interactiveYoutubeWrapper" class="w-100 h-100 position-relative">
											<div :id="interactiveYoutubePlayerId" class="w-100 h-100" />
											<!-- Chặn hover/click native của iframe để YouTube không bật title, pause icon, share và video đề xuất lên lớp video tương tác. -->
											<div class="content-hub-youtube-clean-shield" aria-hidden="true" />
										</div>
										<!-- Video trực tiếp cũng dùng play/seek/timeline tùy chỉnh để không xuất hiện thanh thời gian thứ hai. -->
										<video v-else ref="interactiveHtmlPlayer" class="w-100 h-100" @play="interactiveVideoPlaying = true" @pause="interactiveVideoPlaying = false" @timeupdate="onInteractiveHtmlTimeUpdate" @loadedmetadata="onInteractiveHtmlMetadata">
											<source :src="interactiveVideoEmbedUrl" type="video/mp4" />
										</video>
									</div>

									<!-- Mỗi chấm là một timerMarker; nhiều câu hỏi có thể cùng thuộc một mốc thời gian. -->
									<div ref="interactiveTimelineTrack" class="content-hub-interactive-timeline" @mousedown="onInteractiveTimelineMouseDown" @touchstart="onInteractiveTimelineMouseDown">
										<!-- Commit lại seek sau khi Vuetify cập nhật thumb để timer player không kéo ngược slider về vị trí cũ. -->
										<v-slider v-model="interactiveVideoCurrentTime" :max="interactiveVideoDuration || 100" min="0" step="1" hide-details density="compact" color="primary" track-color="grey-lighten-2" :track-size="4" :thumb-size="12" class="w-100" @click.stop="onInteractiveTimelineSliderCommit" @touchend="onInteractiveTimelineSliderCommit" />
										<div v-for="marker in interactiveVideoInteractions" :key="marker.id" class="content-hub-interactive-marker" :style="{ left: ((marker.time / (interactiveVideoDuration || 1)) * 96) + 2 + '%' }" :title="formatTime(marker.time) + ' · ' + marker.questions.length + ' câu hỏi'" @mousedown.stop.prevent="startDragInteractiveMarker(marker, $event)" @touchstart.stop.prevent="startDragInteractiveMarker(marker, $event)">
											<span v-if="marker.questions.length > 1" class="content-hub-interactive-marker-count">{{ marker.questions.length }}</span>
										</div>
									</div>
									<div class="d-flex align-center justify-space-between flex-wrap ga-2 mt-2">
										<div class="d-flex align-center ga-2"><v-btn icon size="small" variant="tonal" color="primary" @click="toggleInteractiveVideoPlay"><v-icon>{{ interactiveVideoPlaying ? 'mdi-pause' : 'mdi-play' }}</v-icon></v-btn><span class="text-caption font-weight-medium">{{ formatTime(interactiveVideoCurrentTime) }} / {{ formatTime(interactiveVideoDuration) }}</span></div>
										<v-btn size="small" color="success" prepend-icon="mdi-plus" @click="addInteractiveQuestionAtCurrentTime">Thêm câu hỏi tại thời gian hiện tại</v-btn>
									</div>

									<v-card v-if="interactiveVideoInteractions.length" variant="outlined" class="mt-3">
										<v-card-title class="text-subtitle-2 d-flex align-center justify-space-between"><span>Danh sách mốc và câu hỏi tương tác</span><v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="addInteractiveMarker">Thêm mốc thủ công</v-btn></v-card-title>
										<v-card-text class="pa-2">
											<div v-for="(marker, markerIndex) in interactiveVideoInteractions" :key="marker.id" class="content-hub-interactive-marker-group mb-3">
												<div class="d-flex align-center ga-2 mb-2">
													<v-text-field :model-value="formatTime(marker.time)" label="TimerMarker" variant="outlined" density="compact" hide-details class="content-hub-interactive-time" @change="onInteractiveMarkerTimeChange(marker, $event)" @blur="onInteractiveMarkerTimeChange(marker, $event)" />
													<v-chip size="small" color="primary" variant="tonal">{{ marker.questions.length }} câu hỏi</v-chip>
													<v-spacer />
													<v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click="addInteractiveQuestionToMarker(marker)">Thêm câu tại mốc này</v-btn>
													<v-btn icon size="small" variant="text" color="error" title="Xóa mốc và các câu hỏi" @click="removeInteractiveMarker(markerIndex)"><v-icon>mdi-delete-outline</v-icon></v-btn>
												</div>
												<div v-for="(question, questionIndex) in marker.questions" :key="question.id" class="content-hub-interactive-question-row d-flex align-start ga-2 mb-2 ml-3">
													<div class="flex-grow-1 text-body-2">
														<div class="d-flex align-center flex-wrap ga-2 mb-1">
															<v-chip size="x-small" color="secondary" variant="tonal">Câu {{ questionIndex + 1 }}</v-chip>
															<v-chip size="x-small" color="primary" variant="tonal">{{ getTypeLabel(question.type) }}</v-chip>
														</div>
														<!-- Preview phải render rich-text/LaTex thay vì in raw HTML như <p>…</p>; chỉnh sửa thực hiện qua nút cấu hình. -->
														<!-- Câu hỏi tương tác dùng cùng quy tắc hiển thị với ngân hàng: chỉ môn Tin học mới escape mã HTML để hiện nguyên văn. -->
														<uc-latex-view :content="getQuestionDisplayContent(question.content?.prompt || question.config?.questionText || '')" :literal-html-tags="isComputerSubjectContext" />
														<!-- Đáp án dùng cùng ConfigJson với dialog để người soạn rà nhanh đáp án đúng mà không phải mở từng câu. -->
														<div v-if="getInteractiveCorrectAnswer(question)" class="d-flex align-start ga-1 text-caption text-success mt-1">
															<span class="font-weight-bold flex-shrink-0">Đáp án đúng:</span>
																	<uc-latex-view :content="getQuestionDisplayContent(getInteractiveCorrectAnswer(question))" :literal-html-tags="isComputerSubjectContext" />
														</div>
														<!-- Hiển thị giới hạn ngay trên danh sách để giáo viên không phải mở lại từng câu mới biết yêu cầu trả lời. -->
														<div v-if="getInteractiveResponseLimit(question)" class="content-hub-interactive-response-limit">
															<v-icon size="13" class="mr-1">mdi-format-letter-case</v-icon>{{ getInteractiveResponseLimit(question) }}
														</div>
													</div>
													<v-btn icon size="small" variant="text" color="primary" title="Chỉnh câu hỏi" @click="openInteractiveQuestion(marker, question)"><v-icon>mdi-cog-outline</v-icon></v-btn>
													<v-btn icon size="small" variant="text" color="error" title="Xóa câu hỏi khỏi mốc" @click="removeInteractiveQuestion(marker, questionIndex)"><v-icon>mdi-close</v-icon></v-btn>
												</div>
											</div>
										</v-card-text>
									</v-card>
								</div>
							</div>
						</div>
						<div v-else-if="pendingUploadType === 'AUDIO'" class="upload-content-section">
							<div class="upload-section-label"><v-icon size="16">mdi-link-variant</v-icon><span>Dán link audio</span></div>
							<v-row dense align="center">
								<v-col cols="12" md="8"><v-text-field v-model="uploadAudioUrl" placeholder="https://.../audio.mp3" variant="outlined" density="compact" hide-details="auto" append-inner-icon="mdi-link" @keydown.enter="saveAudioLink" /></v-col>
								<v-col cols="12" md="4"><v-btn block color="primary" variant="tonal" :disabled="!uploadAudioUrl.trim()" @click="saveAudioLink">Lưu link audio</v-btn></v-col>
							</v-row>
							<div class="upload-section-divider"><span>hoặc</span></div>
							<v-btn block variant="outlined" color="primary" prepend-icon="mdi-cloud-upload-outline" @click="$refs.audioUploadInput?.click()">Tải audio lên LMS &amp; Google Drive</v-btn>
							<!-- Lấy File thật từ input; không truyền trực tiếp Event vào UploadManager vì FormData sẽ gửi [object Event]. -->
							<input ref="audioUploadInput" type="file" accept="audio/*" class="d-none" @change="uploadAudioToLms($event)" />
						</div>
						<div v-else-if="pendingUploadType === 'HTML'" class="upload-content-section">
							<!-- HTML trong Content Hub là một tệp tải lên; không hiển thị mã nguồn dài trong dialog. -->
							<div class="upload-info-banner"><v-icon size="18" color="primary">mdi-information-outline</v-icon><span>Chọn tệp .html hoặc .htm, hệ thống sẽ lưu trực tiếp vào kho.</span></div>
							<v-file-input accept=".html,.htm" label="Tải tệp HTML" placeholder="Chọn tệp HTML" prepend-icon="mdi-code-tags" variant="outlined" density="compact" hide-details="auto" @update:modelValue="importHtmlDocument" />
						</div>
						<div v-else-if="pendingUploadType === 'IMAGE'" class="upload-content-section">
							<div class="upload-info-banner"><v-icon size="18" color="primary">mdi-image-outline</v-icon><span>Chọn hình ảnh để thêm vào kho tài liệu.</span></div>
							<v-file-input accept="image/*" label="Tải hình ảnh" placeholder="Chọn tệp hình ảnh" prepend-icon="mdi-image-plus-outline" variant="outlined" density="compact" hide-details="auto" @update:modelValue="uploadImageFile" />
						</div>
						<div v-else-if="pendingUploadType === 'SLIDE'" class="upload-content-section">
							<v-tabs v-model="uploadSlideTab" density="compact" color="primary" class="upload-slide-tabs"><v-tab value="upload">Tải file lên</v-tab><v-tab value="link">Dán link Slides / Canva</v-tab></v-tabs>
							<v-window v-model="uploadSlideTab" class="upload-slide-window mt-2">
								<!-- Tài liệu văn phòng cần có bản LMS để quản lý nội bộ và bản Google Drive để mở/preview theo luồng Content Hub. -->
								<v-window-item value="upload" class="upload-slide-panel"><v-file-input accept=".doc,.docx,.ppt,.pptx,.pdf" label="Tải tài liệu" placeholder="Chọn PPT, DOC hoặc PDF để lưu vào LMS & Google Drive" prepend-icon="mdi-file-upload-outline" variant="outlined" density="compact" hide-details="auto" @update:modelValue="uploadSlideToDrive" /></v-window-item>
								<v-window-item value="link" class="upload-slide-panel">
									<v-row dense align="center">
										<v-col cols="12" md="8"><v-text-field v-model="uploadSlideUrl" label="Link Google Slides / Canva" placeholder="Dán đường dẫn chia sẻ tại đây" variant="outlined" density="compact" hide-details="auto" append-inner-icon="mdi-link" @keydown.enter="saveSlideDocumentLink" /></v-col>
										<v-col cols="12" md="4"><v-btn block color="primary" variant="tonal" :disabled="!uploadSlideUrl.trim()" @click="saveSlideDocumentLink">Lưu link</v-btn></v-col>
									</v-row>
								</v-window-item>
							</v-window>
						</div>
						<div v-else-if="pendingUploadType === 'ISPRING_CONTENT'" class="upload-content-section">
							<!-- Đồng bộ luồng iSpring với Soạn học liệu: nhận folder, kéo-thả, kiểm tra index.html và báo tiến độ. -->
							<div class="upload-info-banner"><v-icon size="18" color="primary">mdi-folder-information-outline</v-icon><span>Chọn hoặc kéo-thả nguyên folder iSpring có file index.html.</span></div>
							<div class="ispring-upload-zone" @click="$refs.iSpringFolderInput?.click()" @dragover.prevent @drop.prevent="uploadISpringFolder">
								<v-icon size="34" color="primary" class="mb-1">mdi-folder-upload-outline</v-icon>
								<div class="font-weight-medium">Tải folder iSpring</div>
								<div class="text-caption text-medium-emphasis">Bấm để chọn folder hoặc kéo thả vào đây</div>
							</div>
							<input ref="iSpringFolderInput" type="file" webkitdirectory multiple class="d-none" @change="uploadISpringFolder" />
							<div v-if="ispringUploadProgress.show" class="mt-3">
								<v-progress-linear :model-value="ispringUploadProgress.percent" color="primary" height="6" rounded />
								<div class="text-caption text-medium-emphasis mt-1">{{ ispringUploadProgress.text }}</div>
							</div>
						</div>
					</div>
				</div>

				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="dialogUpload = false">Hủy</v-btn>
					<v-btn v-if="pendingUploadType === 'VIDEO' && uploadVideoMode === 'STANDARD'" color="primary" elevation="0" :disabled="!uploadVideoUrl.trim()" @click="saveVideoLink">Lưu link YouTube</v-btn>
					<v-btn v-else-if="pendingUploadType === 'VIDEO' && uploadVideoMode === 'INTERACTIVE'" color="primary" elevation="0" :disabled="!interactiveVideoUrl.trim()" @click="saveInteractiveVideo">Lưu video tương tác</v-btn>
				</template>
			</uc-dialog>

			<!-- Mỗi mốc giữ schema câu hỏi tương thích Ngân hàng câu hỏi để video có thể dùng đủ dạng câu hỏi và đáp án. -->
			<!-- Form này dùng lại nhịp Type / Điểm / Cách chấm và rich editor của tab Ngân hàng câu hỏi; chỉ bỏ Nhóm và Media vì chúng thuộc video hiện hành. -->
			<uc-dialog v-model="interactiveQuestionDialog" width="760" :is-show-done-btn="false" :title="interactiveEditing ? 'Thiết kế câu hỏi tương tác (' + formatTime(interactiveEditing.time) + ')' : 'Thiết kế câu hỏi tương tác'">
				<div v-if="interactiveEditing" class="pa-2">
					<v-row dense class="mb-3">
						<v-col cols="6"><v-select v-model="interactiveEditing.question.type" :items="TypeOptions" item-title="label" item-value="value" label="Loại câu hỏi *" variant="outlined" density="compact" hide-details @update:modelValue="onInteractiveQuestionTypeChange" /></v-col>
						<!-- Video tương tác cũng giữ text cho môn Tin học để không bị locale đổi dấu chấm thành dấu phẩy. -->
						<v-col cols="3"><v-text-field v-model="interactiveEditing.question.config.points" label="Điểm" :type="isComputerSubjectContext ? 'text' : 'number'" inputmode="decimal" min="0" :step="isComputerSubjectContext ? 0.25 : 0.5" variant="outlined" density="compact" hide-details /></v-col>
						<v-col cols="3"><v-select v-model="interactiveEditing.question.config.gradingType" :items="gradingTypeOptions" label="Cách chấm" item-title="title" item-value="value" variant="outlined" density="compact" hide-details :disabled="!isQuestionAutoGradable(interactiveEditing.question.type) || interactiveEditing.question.type === 'QUIZ_ORDERING'" :clearable="false" /></v-col>
					</v-row>
					<uc-rich-text-editor :key="'interactive-question-' + interactiveEditing.id" v-model="interactiveEditing.question.content.prompt" label="Nội dung câu hỏi *" :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="3" auto-grow class="mb-3" @update:modelValue="interactiveEditing.question.config.questionText = $event" />

					<!-- Các phần dưới đây chỉ hiện đúng control của loại đã chọn, cùng cấu trúc ConfigJson với Ngân hàng câu hỏi. -->
					<template v-if="['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'].includes(interactiveEditing.question.type)">
						<div class="text-subtitle-2 font-weight-bold mb-2">Đáp án</div>
						<!-- BẮT BUỘC: Vuetify 3 yêu cầu v-radio phải nằm trong v-radio-group để đảm bảo chỉ chọn 1 đáp án đúng cho câu hỏi trắc nghiệm 1 đáp án (QUIZ_SINGLE_CHOICE). -->
						<v-radio-group v-if="interactiveEditing.question.type === 'QUIZ_SINGLE_CHOICE'" v-model="interactiveEditing.question.config.correctAnswer" hide-details class="ma-0 pa-0">
							<v-row v-for="(option, index) in interactiveEditing.question.config.options" :key="index" dense align="center" class="question-option-row mb-2">
								<v-col cols="1" class="d-flex align-center justify-center">
									<v-radio :value="index" hide-details />
								</v-col>
								<v-col cols="10"><v-text-field v-model="interactiveEditing.question.config.options[index]" :label="'Đáp án ' + (index + 1)" variant="outlined" density="compact" hide-details /></v-col>
								<v-col cols="1" class="d-flex align-center justify-center"><v-btn v-if="interactiveEditing.question.config.options.length > 2" icon size="x-small" variant="text" color="error" title="Xóa đáp án" @click="removeInteractiveOption(index)"><v-icon>mdi-close</v-icon></v-btn></v-col>
							</v-row>
						</v-radio-group>
						<!-- Trắc nghiệm nhiều đáp án dùng checkbox cho từng lựa chọn -->
						<template v-else-if="interactiveEditing.question.type === 'QUIZ_MULTIPLE_CHOICE'">
							<v-row v-for="(option, index) in interactiveEditing.question.config.options" :key="index" dense align="center" class="question-option-row mb-2">
								<v-col cols="1" class="d-flex align-center justify-center"><v-checkbox v-model="interactiveEditing.question.config.correctAnswers" :value="index" hide-details density="compact" /></v-col>
								<v-col cols="10"><v-text-field v-model="interactiveEditing.question.config.options[index]" :label="'Đáp án ' + (index + 1)" variant="outlined" density="compact" hide-details /></v-col>
								<v-col cols="1" class="d-flex align-center justify-center"><v-btn v-if="interactiveEditing.question.config.options.length > 2" icon size="x-small" variant="text" color="error" title="Xóa đáp án" @click="removeInteractiveOption(index)"><v-icon>mdi-close</v-icon></v-btn></v-col>
							</v-row>
						</template>
						<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="addInteractiveOption">Thêm đáp án</v-btn>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'QUIZ_TRUE_FALSE'">
						<div class="text-subtitle-2 font-weight-bold mb-2">Đáp án đúng</div>
						<v-radio-group v-model="interactiveEditing.question.config.correctAnswer" inline hide-details>
							<v-radio :value="true" label="Đúng" color="success" />
							<v-radio :value="false" label="Sai" color="error" />
						</v-radio-group>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'QUIZ_MULTIPLE_TRUE_FALSE'">
						<div class="text-subtitle-2 font-weight-bold mb-2">Các mệnh đề Đúng / Sai</div>
						<div v-for="(statement, index) in interactiveEditing.question.config.options" :key="index" class="d-flex align-center ga-2 mb-2">
							<v-btn size="small" :variant="statement.correctAnswer ? 'flat' : 'outlined'" color="success" @click="statement.correctAnswer = true; statement.inCorrectAnswer = false">Đúng</v-btn>
							<v-btn size="small" :variant="statement.inCorrectAnswer ? 'flat' : 'outlined'" color="error" @click="statement.inCorrectAnswer = true; statement.correctAnswer = false">Sai</v-btn>
							<v-text-field v-model="statement.text" label="Nội dung mệnh đề" variant="outlined" density="compact" hide-details class="flex-grow-1" />
							<v-btn v-if="interactiveEditing.question.config.options.length > 2" icon size="x-small" variant="text" color="error" title="Xóa mệnh đề" @click="interactiveEditing.question.config.options.splice(index, 1)"><v-icon>mdi-close</v-icon></v-btn>
						</div>
						<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="interactiveEditing.question.config.options.push({ text: '', correctAnswer: false, inCorrectAnswer: false })">Thêm mệnh đề</v-btn>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'QUIZ_FILL_IN_BLANK'">
						<div class="text-subtitle-2 font-weight-bold mb-2">Nội dung và chỗ trống</div>
						<div v-for="(part, index) in interactiveEditing.question.config.parts" :key="part.id || index" class="d-flex align-center ga-2 mb-2">
							<v-chip size="x-small" variant="tonal" :color="part.type === 'blank' ? 'primary' : 'default'">{{ part.type === 'blank' ? 'Chỗ trống' : 'Văn bản' }}</v-chip>
							<v-text-field v-if="part.type === 'text'" v-model="part.value" label="Văn bản" variant="outlined" density="compact" hide-details class="flex-grow-1" />
							<v-text-field v-else v-model="part.correctAnswer" label="Đáp án đúng" hint="Có thể ngăn cách các đáp án bằng dấu /" persistent-hint variant="outlined" density="compact" class="flex-grow-1" @update:modelValue="part.acceptedAnswers = String($event || '').split('/').map(answer => answer.trim()).filter(Boolean)" />
							<v-btn icon size="x-small" variant="text" color="error" title="Xóa phần" @click="interactiveEditing.question.config.parts.splice(index, 1)"><v-icon>mdi-close</v-icon></v-btn>
						</div>
						<div class="d-flex ga-2"><v-btn size="small" variant="tonal" @click="interactiveEditing.question.config.parts.push({ type: 'text', value: '' })">Thêm văn bản</v-btn><v-btn size="small" variant="tonal" color="primary" @click="interactiveEditing.question.config.parts.push({ type: 'blank', id: 'blank_' + Date.now(), correctAnswer: '', acceptedAnswers: [] })">Thêm chỗ trống</v-btn></div>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'QUIZ_MATCHING'">
						<div class="text-subtitle-2 font-weight-bold mb-2">Các cặp ghép nối</div>
						<v-row v-for="(left, index) in interactiveEditing.question.config.columnA" :key="index" dense align="center" class="mb-2">
							<v-col cols="5"><v-text-field v-model="interactiveEditing.question.config.columnA[index]" label="Cột A" variant="outlined" density="compact" hide-details /></v-col>
							<v-col cols="1" class="text-center"><v-icon>mdi-arrow-right</v-icon></v-col>
							<v-col cols="5"><v-text-field v-model="interactiveEditing.question.config.columnB[index]" label="Cột B" variant="outlined" density="compact" hide-details /></v-col>
							<v-col cols="1"><v-btn v-if="interactiveEditing.question.config.columnA.length > 1" icon size="x-small" variant="text" color="error" title="Xóa cặp" @click="interactiveEditing.question.config.columnA.splice(index, 1); interactiveEditing.question.config.columnB.splice(index, 1)"><v-icon>mdi-close</v-icon></v-btn></v-col>
						</v-row>
						<v-btn size="small" variant="tonal" prepend-icon="mdi-plus" @click="interactiveEditing.question.config.columnA.push(''); interactiveEditing.question.config.columnB.push('')">Thêm cặp nối</v-btn>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'QUIZ_ORDERING'">
						<div class="text-subtitle-2 font-weight-bold mb-2">Các ý theo thứ tự đúng</div>
						<p class="text-caption text-medium-emphasis mb-2">Thứ tự đang hiển thị là đáp án đúng.</p>
						<div v-for="(entry, index) in interactiveEditing.question.config.items" :key="entry.id || index" class="d-flex align-center ga-2 mb-2">
							<v-chip size="small" color="primary" variant="tonal">{{ index + 1 }}</v-chip>
							<v-text-field v-model="entry.text" label="Nội dung ý" variant="outlined" density="compact" hide-details class="flex-grow-1" />
							<v-btn icon="mdi-arrow-up" size="small" variant="text" :disabled="index === 0" @click="moveInteractiveOrderingItem(index, -1)" />
							<v-btn icon="mdi-arrow-down" size="small" variant="text" :disabled="index === interactiveEditing.question.config.items.length - 1" @click="moveInteractiveOrderingItem(index, 1)" />
							<v-btn v-if="interactiveEditing.question.config.items.length > 2" icon="mdi-delete-outline" size="small" variant="text" color="error" @click="removeInteractiveOrderingItem(index)" />
						</div>
						<v-btn size="small" variant="tonal" color="primary" prepend-icon="mdi-plus" @click="addInteractiveOrderingItem">Thêm ý</v-btn>
						<p class="text-caption text-medium-emphasis mt-2 mb-0">Chấm đều: mỗi ý đúng vị trí = tổng điểm câu / số ý.</p>
					</template>

					<!-- Tự luận và trả lời ngắn không có đáp án đúng để chấm tự động; vẫn cần lưu hướng dẫn làm bài để màn hình học sinh dùng đúng cấu hình. -->
					<template v-else-if="interactiveEditing.question.type === 'SHORT_ANSWER'">
						<v-textarea v-model="interactiveEditing.question.config.instruction" label="Hướng dẫn trả lời (không bắt buộc)" placeholder="Ví dụ: Trả lời ngắn gọn trong 1–2 câu..." variant="outlined" density="compact" rows="2" auto-grow hide-details="auto" />
						<v-text-field v-model.number="interactiveEditing.question.config.maxLength" label="Số ký tự tối đa (0 = không giới hạn)" type="number" min="0" variant="outlined" density="compact" hide-details="auto" class="mt-2" />
						<!-- Đáp án tham khảo được lưu trong config để giáo viên xem khi chấm, học sinh không nhận được trường này trong form trả lời. -->
						<uc-rich-text-editor v-model="interactiveEditing.question.config.referenceAnswer" label="Đáp án tham khảo (chỉ giáo viên xem)" placeholder="Nhập câu trả lời hoặc các ý chính tham khảo..." :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="3" auto-grow class="mt-2" />
						<v-alert density="compact" variant="tonal" color="info" class="mt-2">Học sinh nhập câu trả lời ngắn; giáo viên sẽ chấm thủ công.</v-alert>
					</template>

					<template v-else-if="interactiveEditing.question.type === 'ESSAY'">
						<v-textarea v-model="interactiveEditing.question.config.instruction" label="Hướng dẫn làm bài (không bắt buộc)" placeholder="Nhập yêu cầu hoặc tiêu chí gợi ý cho bài tự luận..." variant="outlined" density="compact" rows="2" auto-grow hide-details="auto" />
						<v-row dense class="mt-1">
							<v-col cols="6"><v-text-field v-model.number="interactiveEditing.question.config.minWords" label="Số từ tối thiểu" type="number" min="0" variant="outlined" density="compact" hide-details="auto" /></v-col>
							<v-col cols="6"><v-text-field v-model.number="interactiveEditing.question.config.maxLength" label="Số ký tự tối đa" type="number" min="0" variant="outlined" density="compact" hide-details="auto" /></v-col>
						</v-row>
						<!-- Tự luận dùng cùng key referenceAnswer với câu hỏi trong ngân hàng để trang chấm bài đọc được một schema duy nhất. -->
						<uc-rich-text-editor v-model="interactiveEditing.question.config.referenceAnswer" label="Đáp án tham khảo (chỉ giáo viên xem)" placeholder="Nhập ý chính hoặc đáp án tham khảo..." :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="3" auto-grow class="mt-2" />
						<v-alert density="compact" variant="tonal" color="info" class="mt-2">Học sinh soạn câu trả lời tự luận; giáo viên sẽ chấm thủ công.</v-alert>
					</template>

					<v-alert v-else density="compact" variant="tonal" color="info">Loại câu hỏi này học sinh trả lời tự do và giáo viên chấm thủ công.</v-alert>
				</div>
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="interactiveQuestionDialog = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" @click="confirmInteractiveQuestion">Xác nhận</v-btn>
				</template>
			</uc-dialog>

				<!-- Hai nguồn import dùng chung preview: kỹ năng được gán trước khi ghi câu hỏi vào GroupId hiện tại. -->
				<uc-dialog v-model="dialogImport" :title="importDialogTitle" width="1000">
					<div v-if="importLoading" class="d-flex justify-center py-8"><v-progress-circular indeterminate color="primary" /></div>
					<v-alert v-else-if="importError" type="warning" variant="tonal" density="compact">{{ importError }}</v-alert>
					<div v-else>
						<!-- Chỉ các cấp còn dùng taxonomy mới cần hướng dẫn và chọn mức độ khi import. -->
						<v-alert v-if="!isPrimarySchoolContext" density="compact" variant="tonal" color="info" class="mb-3">Gán mức độ là tùy chọn. Nếu chọn mức độ mặc định, hệ thống sẽ gán nhanh cho cả lô; nếu để trống, câu hỏi vẫn import bình thường và được đưa vào group “Chưa xác định mức độ” để bổ sung sau.</v-alert>
						<div class="d-flex align-center justify-space-between mb-2">
							<v-checkbox :model-value="allImportQuestionsSelected" label="Chọn tất cả câu được hỗ trợ" hide-details density="compact" @update:model-value="toggleAllImportQuestions" />
							<span class="text-caption text-medium-emphasis">{{ selectedImportCount }}/{{ importQuestions.filter(item => item._supported).length }} câu</span>
						</div>
						<v-row v-if="!isPrimarySchoolContext" dense align="center" class="mb-2">
							<v-col cols="12" md="8">
								<v-select v-model="importDefaultSkillIds" :items="DSSkill" item-title="TenKyNang" item-value="KyNang_MonHoc_ChiTietID" label="Mức độ mặc định cho lô import (không bắt buộc)" multiple chips closable-chips :loading="skillsLoading" :disabled="!DSSkill.length" variant="outlined" density="compact" hide-details="auto" no-data-text="Chưa có mức độ câu hỏi">
									<template #item="{ props, item }"><v-list-item v-bind="props" :subtitle="item.raw.NhomKyNang || ''" /></template>
								</v-select>
							</v-col>
							<v-col cols="12" md="4" class="d-flex align-center">
								<v-btn block variant="tonal" color="primary" :disabled="!importDefaultSkillIds.length || !selectedImportCount" @click="applyImportDefaultSkills">Áp dụng cho câu đã chọn</v-btn>
							</v-col>
						</v-row>
						<v-alert v-if="!isPrimarySchoolContext && selectedImportSkillMissingCount" density="compact" variant="tonal" color="warning" class="mb-3">{{ selectedImportSkillMissingCount }} câu chưa xác định mức độ. Nếu tiếp tục import, các câu này sẽ nằm trong group “Chưa xác định mức độ” để xử lý sau.</v-alert>
						<div v-if="importQuestions.length" class="border rounded">
							<div v-for="question in importQuestions" :key="question._key" class="px-3 py-2 border-b">
								<v-row dense align="center">
									<v-col cols="12" :md="isPrimarySchoolContext ? 12 : 7">
										<div class="d-flex align-start ga-2">
											<v-checkbox v-model="question._selected" :disabled="!question._supported" hide-details density="compact" class="mt-0" />
											<div class="min-width-0">
												<div class="text-body-2 font-weight-medium">{{ question.TenNoiDung || 'Câu hỏi học liệu' }}</div>
												<div class="text-caption text-medium-emphasis">{{ question.TenHocLieu || question._sourceFileName || 'Nguồn import' }} · {{ getTypeLabel(question.LoaiNoiDung) }} · {{ question.Points || 1 }} điểm<span v-if="!question._supported"> · Chưa hỗ trợ import</span></div>
											</div>
										</div>
									</v-col>
									<!-- Không cho chọn mức độ ở Tiểu học; import vẫn giữ nguyên các trường nội dung khác. -->
									<v-col v-if="!isPrimarySchoolContext" cols="12" md="5">
										<v-select v-model="question._skillIds" :items="DSSkill" item-title="TenKyNang" item-value="KyNang_MonHoc_ChiTietID" label="Mức độ của câu hỏi (không bắt buộc)" multiple chips closable-chips :loading="skillsLoading" :disabled="!question._supported || !DSSkill.length" variant="outlined" density="compact" hide-details="auto" no-data-text="Chưa có mức độ câu hỏi">
											<template #item="{ props, item }"><v-list-item v-bind="props" :subtitle="item.raw.NhomKyNang || ''" /></template>
										</v-select>
									</v-col>
								</v-row>
							</div>
						</div>
						<div v-else class="text-caption text-medium-emphasis text-center py-8">Không có câu hỏi hợp lệ trong nguồn import.</div>
					</div>

					<template #actions>
						<span class="text-caption text-medium-emphasis">Đã chọn {{ selectedImportCount }} câu<span v-if="selectedImportSkillMissingCount"> · chưa xác định mức độ: {{ selectedImportSkillMissingCount }}</span></span>
						<v-spacer />
						<v-btn variant="text" @click="dialogImport = false">Hủy</v-btn>
						<v-btn color="primary" elevation="0" :loading="importSaving" :disabled="!canSaveImportedQuestions" @click="saveImportedQuestions">Import vào nhóm</v-btn>
					</template>
			</uc-dialog>

			<!-- Dialog Import câu hỏi từ JSON dành cho SystemRight = 9 / Admin -->
			<uc-dialog v-model="dialogImportJson" title="Import câu hỏi từ dữ liệu JSON" width="750">
				<div class="px-1">
					<v-alert density="compact" variant="tonal" color="info" class="mb-3">
						Hỗ trợ dán trực tiếp chuỗi JSON được convert từ file (hoặc định dạng <code>{ filename, data: { questions: [...] } }</code>) để import nhanh mà không cần gửi file qua server AI.
					</v-alert>
					<div class="d-flex align-center justify-space-between mb-2">
						<span class="text-caption font-weight-medium">Nhập hoặc tải file JSON:</span>
						<v-btn size="x-small" variant="tonal" color="primary" prepend-icon="mdi-file-upload-outline" @click="$refs.jsonFileInput?.click()">
							Chọn file .json
						</v-btn>
						<input ref="jsonFileInput" type="file" accept=".json" class="d-none" @change="onJsonFileSelected">
					</div>
					<v-textarea
						v-model="jsonImportText"
						placeholder="Dán toàn bộ nội dung JSON câu hỏi vào đây..."
						variant="outlined"
						density="compact"
						rows="12"
						auto-grow
						hide-details="auto"
						class="mb-3 font-monospace text-body-2"
					/>
					<div v-if="parsedJsonImportCount" class="d-flex align-center text-caption text-success font-weight-medium">
						<v-icon size="16" class="mr-1">mdi-check-circle-outline</v-icon>
						<span>Hợp lệ! Tìm thấy {{ parsedJsonImportCount }} câu hỏi (Nguồn: {{ parsedJsonImportData?.filename || 'JSON' }}).</span>
					</div>
					<div v-else-if="jsonImportText.trim()" class="d-flex align-center text-caption text-error font-weight-medium">
						<v-icon size="16" class="mr-1">mdi-alert-circle-outline</v-icon>
						<span>JSON chưa đúng định dạng hoặc không có mảng câu hỏi (questions).</span>
					</div>
				</div>
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="dialogImportJson = false">Hủy</v-btn>
					<v-btn color="primary" elevation="0" :disabled="!parsedJsonImportCount" @click="processImportJson">
						Tiến hành Import ({{ parsedJsonImportCount }} câu)
					</v-btn>
				</template>
			</uc-dialog>

			<uc-dialog v-model="dialogProfileFolder" :title="profileEditingFolderId ? 'Đổi tên thư mục trong Hồ sơ' : 'Tạo thư mục trong Hồ sơ'" width="460">
				<div class="px-1">
					<!-- Tên folder chỉ là metadata của node; không ép theo taxonomy Khối/Môn để người dùng tự xây cây lưu trữ. -->
					<v-text-field v-model="profileFolderForm.name" label="Tên thư mục" placeholder="Ví dụ: Hồ sơ chuyên môn" variant="outlined" density="compact" autofocus hide-details="auto" @keyup.enter="saveProfileFolder" />
				</div>
				<template #actions>
					<v-spacer />
					<v-btn variant="text" @click="dialogProfileFolder = false">Hủy</v-btn>
					<v-btn color="primary" :loading="savingProfileFolder" @click="saveProfileFolder">{{ profileEditingFolderId ? 'Lưu thay đổi' : 'Tạo thư mục' }}</v-btn>
				</template>
			</uc-dialog>

			<!-- Hỗ trợ xem trực tiếp tài liệu trong LMS: PDF được nhúng trực tiếp qua viewer của trình duyệt, các file Office (DOCX, XLSX, PPTX) được hiển thị qua Office Viewer mà không cần chuyển đổi file sang Google Slides. -->
			<v-dialog v-model="previewDialog" fullscreen transition="dialog-bottom-transition">
				<v-card class="d-flex flex-column content-hub-preview-card" style="height: 100vh;">
					<v-toolbar color="primary" density="compact" flat class="content-hub-preview-toolbar">
						<v-icon color="white" class="ml-2 mr-2">{{ isImage({ displayName: previewTitle }) ? 'mdi-image-outline' : (isPdf({ displayName: previewTitle }) ? 'mdi-file-pdf-box' : 'mdi-file-document-edit-outline') }}</v-icon>
						<v-toolbar-title class="text-white text-truncate">{{ previewTitle || 'Xem tài liệu' }}</v-toolbar-title>
						<v-spacer />
						<v-btn color="white" size="small" variant="text" aria-label="Đóng" @click="previewDialog = false">
							<v-icon>mdi-close</v-icon>
							<v-tooltip activator="parent" location="bottom">Đóng</v-tooltip>
						</v-btn>
					</v-toolbar>
					<div class="content-hub-preview-frame flex-grow-1" :style="previewCropTop ? { overflow: 'hidden' } : ''">
						<!-- Nếu là tài liệu HTML lưu text trực tiếp trong DataJson thì render qua srcdoc, ngược lại tải qua URL -->
						<iframe v-if="previewDialog && previewHtmlContent" :srcdoc="previewHtmlContent" title="HTML Document preview" width="100%" height="100%" frameborder="0" allowfullscreen style="border: none; width: 100%; height: 100%; background: #ffffff;" />
						<!-- Ảnh phải dùng thẻ img và URL binary LMS; iframe Google Drive /preview trả về HTML trung gian nên không hiển thị ảnh ổn định. -->
						<v-img v-else-if="previewDialog && previewImageUrl" :src="previewImageUrl" :alt="previewTitle || 'Hình ảnh'" contain class="w-100 h-100" />
						<iframe v-else-if="previewDialog" :src="previewUrl" title="Document preview" width="100%" height="100%" frameborder="0" allowfullscreen :style="previewCropTop ? { border: 'none', width: '100%', marginTop: '-' + previewCropTop + 'px', height: 'calc(100% + ' + previewCropTop + 'px)' } : { border: 'none', width: '100%', height: '100%' }" />
					</div>
				</v-card>
			</v-dialog>
	</Global>
</template>

<script>
	export default {
		name: 'uc-main-layout',
	components: {
		'uc-latex-edit': {
			name: 'uc-latex-edit',
			props: {
				content: {
					type: String,
					default: ''
				},
				isEditable: {
					type: Boolean,
					default: true
				}
			},
			data() {
				return {
					contentEditor: this.content,
					renderedContent: '',
					// Khởi tạo trước nội dung xem trước bằng hàm làm sạch MathML để khi mở dialog không bị trống
					previewContent: this.preprocessMathML ? this.preprocessMathML(this.content || '') : (this.content || ''),
					// Điều khiển mở/đóng uc-dialog theo chuẩn hệ thống (không dùng isActive từ slot v-dialog)
					dialogOpen: false,
					vueData
				}
			},
			computed: {
				isEmpty() {
					return !this.content || this.content.trim() === ''
				},
				previewEmpty() {
					return !this.contentEditor || this.contentEditor.trim() === ''
				}
			},
			watch: {
				content: {
					immediate: true,
					handler(newContent) {
						this.contentEditor = newContent
						this.renderContent(newContent)
						// Bắt buộc render cả preview khi content prop khởi tạo/thay đổi để vùng xem trước hiển thị ngay lập tức
						this.renderPreview(newContent)
					}
				},
				contentEditor(newContent) {
					this.renderPreview(newContent)
				}
			},
			mounted() {
				this.renderContent(this.content)
				// Khởi tạo preview khi component được mount
				this.renderPreview(this.content)
			},
			methods: {
				preprocessMathML(content) {
					let result = content;
					if (!result) return ''
					for (let i = 0; i < 10; i++) {
						const before = result;
						result = result.replace(
							/<mfenced([^>]+open="\{"[^>]*)>([\s\S]*?)<\/mfenced>/g,
							(fullMatch, attributes, innerContent) => {
								const hasClosingBrace = /close="\}"/.test(attributes);
								if (hasClosingBrace) {
									return `<mo>{</mo><mrow>${innerContent}</mrow><mo>}</mo>`;
								} else {
									return `<mo>{</mo><mrow>${innerContent}</mrow>`;
								}
							}
						);
						if (before === result) break;
					}
					return result;
				},
				escapeHtmlTagsForDisplay(content) {
					// Nội dung đáp án môn Tin học có thể là HTML comment (<!-- ... -->), DOCTYPE hoặc thẻ web.
					// Nếu đưa trực tiếp vào v-html, comment sẽ biến mất còn các thẻ như h1/table sẽ bị thực thi.
					// Chỉ escape bản hiển thị; contentEditor vẫn giữ mã nguồn gốc để lưu và chỉnh sửa đúng.
					return String(content ?? '').replace(/<!--[\s\S]*?-->|<!DOCTYPE[^>]*>|<\/?[A-Za-z][^>]*>/gi, tag => tag.replace(/</g, '&lt;').replace(/>/g, '&gt;'))
				},
				renderContent(content) {
					if (!content) {
						this.renderedContent = ''
						return
					}
					// Activator chỉ là vùng xem nhanh; escape trước khi truyền vào component có v-html.
					this.renderedContent = this.escapeHtmlTagsForDisplay(content);
				},
				renderPreview(content) {
					if (!content) {
						this.previewContent = ''
						return
					}
					// Preview trong hộp sửa cũng phải hiển thị <!-- ... --> như chữ, không để HTML engine ẩn nội dung.
					this.previewContent = this.escapeHtmlTagsForDisplay(content);
				},
				saveContent() {
					const val = this.preprocessMathML(this.contentEditor || '');
					this.$emit('update:content', val);
					this.$emit('update:modelValue', val);
					// Đóng uc-dialog bằng v-model chuẩn thay vì isActive từ slot v-dialog
					this.dialogOpen = false;
				},
				cancelEdit() {
					this.contentEditor = this.content
					this.dialogOpen = false
				}
			},
			template: '<div class="uc-latex-edit-wrapper w-100">' +
				'<!-- Activator: click vào đây để mở uc-dialog -->' +
				'<div class="uc-latex-edit-activator w-100" @click="isEditable && (dialogOpen = true)">' +
					'<div v-if="isEditable">' +
						'<div v-if="isEmpty" class="cursor-pointer empty-content text-caption">' +
							'Bấm để <v-icon color="success" size="small">mdi-pencil</v-icon> soạn nội dung...' +
						'</div>' +
						'<div v-else class="cursor-pointer filled-content">' +
							'<uc-latex-view ref="contentContainer" class="uc-latex-edit" :content="renderedContent" :escapeHtml="true" :literalHtmlTags="true" />' +
						'</div>' +
					'</div>' +
					'<div v-else>' +
						'<uc-latex-view ref="contentContainer" class="uc-latex-edit" :content="renderedContent" :escapeHtml="true" :literalHtmlTags="true" />' +
					'</div>' +
				'</div>' +
				'<!-- Dialog chỉnh sửa dùng uc-dialog chuẩn hệ thống thay cho v-dialog -->' +
				'<uc-dialog v-model="dialogOpen" title="Chỉnh sửa nội dung" width="900">' +
					'<uc-rich-text-editor v-model="contentEditor" :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="6" auto-grow label="Nội dung (hỗ trợ HTML, LaTeX & công thức)" />' +
					'<!-- Preview: hiển thị ngay khi mở dialog, cập nhật theo từng keystroke người dùng -->' +
					'<div class="preview-section mt-4">' +
						'<label class="text-subtitle-2 mb-2 font-weight-medium d-block">Xem trước:</label>' +
						'<div class="preview-content uc-latex-edit pa-2 border rounded bg-grey-lighten-5">' +
							'<div v-if="previewEmpty" class="text-grey"><em>Không có nội dung...</em></div>' +
							'<uc-latex-view v-else ref="previewContainer" :content="previewContent" :escapeHtml="true" :literalHtmlTags="true" />' +
						'</div>' +
					'</div>' +
					'<template #actions>' +
						'<v-spacer />' +
						'<v-btn variant="text" @click="cancelEdit()">Hủy</v-btn>' +
						'<v-btn color="primary" elevation="0" @click="saveContent()">Lưu</v-btn>' +
					'</template>' +
				'</uc-dialog>' +
			'</div>'
		},
		'uc-editor-dialog': {
			name: 'uc-editor-dialog',
			props: ['modelValue', 'title', 'placeholder'],
			data() {
				return { content: this.modelValue, vueData }
			},
			watch: {
				modelValue(v) { this.content = v }
			},
			template: `
				<v-dialog :model-value="!!modelValue" max-width="900" persistent>
					<v-card :title="title">
						<v-card-text>
							<uc-rich-text-editor v-model="content" :imageapi="vueData.v_Set && (vueData.v_Set.apiFile || vueData.v_Set.apiImageAdapter)" variant="outlined" rows="10" />
						</v-card-text>
						<v-card-actions>
							<v-spacer />
							<v-btn text="Hủy" variant="text" @click="$emit('update:modelValue', null)"></v-btn>
							<v-btn text="Lưu" color="primary" @click="$emit('update:modelValue', content); $emit('save', content)"></v-btn>
						</v-card-actions>
					</v-card>
				</v-dialog>
			`
		}
	},
	inject: ['snackbarRef', 'iframeRef', 'confirmRef'],
	data() {
		return {
			vueData,
			lastAcademicContextKey: '',
			activeBranch: 'subject',
			activeSection: 'documents',
			treeKhoi: [],
			treeLoading: false,
			selectedMon: null,
			selectedLibraryId: null,
			selectedTreeNode: { kind: 'subject-root' },
			profileCurrentFolderId: null,
			// Giữ riêng danh sách node active để đồng bộ hai chiều với v-treeview và màu chọn hiện tại.
			profileActivatedTreeNodeIds: ['profile-root'],
			profileViewMode: 'cards',
			profileLoading: false,
			// BGH/Admin dùng được cả chế độ giám sát Sáng kiến và Hồ sơ; Tổ trưởng chỉ được giám sát Hồ sơ.
			profileMode: 'personal',
			// Mỗi lần đổi chủ sở hữu/chế độ tăng số phiên để request cũ không ghi đè cây folder mới.
			profileContextRequestId: 0,
			teacherSearchQuery: '',
			selectedTeacherProfile: null,
			assignedTeachers: [],
			initiativeMode: 'personal',
			initiativeTeacherSearchQuery: '',
			selectedTeacherInitiative: null,
			dialogProfileFolder: false,
			// Có giá trị khi dialog đang đổi tên; null giữ nguyên luồng tạo folder mới.
			profileEditingFolderId: null,
			profileFolderForm: { name: '' },
			savingProfileFolder: false,
			selectedGroup: null,
			groupDrawer: false,
			unassignedGroupId: null,
			DSGroup: [],
			DSQuestion: [],
			selectedQuestionSource: 'ALL',
			// Bốn nhóm mức độ chỉ mở sẵn cho các cấp còn dùng taxonomy; Tiểu học hiển thị danh sách phẳng.
			expandedQuestionLevels: {},
			// Trạng thái riêng cho request câu hỏi để đổi nhóm/search không hiển thị nhầm danh sách của request trước.
			questionsLoading: false,
			highlightedQuestionId: null,
			highlightPhase: null,
			highlightQuestionTimer: null,
			highlightQuestionFadeTimer: null,
			updatedQuestionIds: [],
			selectedQuestions: [],
			deletingMultipleQuestions: false,
			dialogGroup: false,
			groupForm: {},
			savingGroup: false,
			dialogQuestion: false,
			questionForm: {},
			// Mức độ được chọn từ bảng trước khi mở dialog tạo/import; null là luồng thao tác chung trên toolbar.
			pendingQuestionLevelId: null,
			// Nội dung nhập tạm cho từng ô trống; chỉ thêm vào acceptedAnswers khi nhấn Enter.
			blankInputs: {},
			savingQuestion: false,
			dialogUpload: false,
			pendingUploadType: '',
			// VIDEO có hai nhánh: giữ luồng phát hành thông thường và bổ sung editor video tương tác theo mốc thời gian.
			uploadVideoMode: 'STANDARD',
			convertingFile: false,
			convertingFileName: '',
			uploadVideoName: '',
			uploadVideoUrl: '',
			uploadAudioUrl: '',
			uploadHtmlContent: '',
			uploadSlideTab: 'upload',
			uploadSlideUrl: '',
			interactiveVideoUrl: '',
			interactiveVideoName: '',
			interactiveVideoId: '',
			// Có giá trị khi editor được mở từ danh sách; dùng NoiDungID để lần lưu sau cập nhật đúng node thay vì tạo video mới.
			interactiveEditingDocument: null,
			interactiveVideoInteractions: [],
			interactiveVideoCurrentTime: 0,
			interactiveVideoDuration: 0,
			interactiveVideoPlaying: false,
			interactiveYoutubePlayerId: 'content-hub-yt-player-' + Math.random().toString(36).slice(2, 9),
			interactiveQuestionDialog: false,
			interactiveEditing: null,
			interactiveTarget: null,
			interactiveVideoTimer: null,
			isDraggingInteractiveTimeline: false,
			isDraggingInteractiveMarker: false,
			ispringUploadProgress: { show: false, percent: 0, text: '' },
			dialogImport: false,
			dialogImportJson: false,
			jsonImportText: '',
			jsonImportFileName: '',
			importLoading: false,
			importSaving: false,
			importError: '',
			importQuestions: [],
			// Chọn nguồn để dùng chung preview/mapping kỹ năng cho import file và import học liệu số.
			importSourceType: 'HOC_LIEU_SO',
			importSourceFileName: '',
			importDefaultSkillIds: [],
			libraries: [],
			nodes: [],
			treeLoadRequestId: 0,
			innovationNodes: [],
			innovationLoading: false,
			sourceFiles: [],
			resourceTypes: [],
			searchQ: '',
							questionSearchTimer: null,
							isRefreshing: false,
			// Khóa các thao tác xóa khác và hiển thị spinner trong suốt hai bước xóa tài nguyên ngoài + node/file LMS.
			deletingDocumentId: null,
			previewDialog: false,
			previewTitle: '',
			previewUrl: '',
			previewImageUrl: '',
							previewHtmlContent: '',
			previewCropTop: 0,
			groupsLoadSeq: 0,
			questionsLoadSeq: 0,
				documentHeaders: [
					{ title: 'Tên tài liệu', key: 'displayName' },
					{ title: 'Nguồn', key: 'sourceLabel', width: 140 },
					{ title: 'Người tạo / Thời gian', key: 'createdInfo', width: 180 },
					{ title: 'Thao tác', key: 'actions', sortable: false, width: 90, align: 'center' },
				],
			questionHeaders: [
				{ title: 'STT', key: 'index', width: 60, sortable: false, align: 'center' },
				// Không đặt width cố định để cột Nội dung câu hỏi tự động co giãn full width 100% theo màn hình
				{ title: 'Nội dung câu hỏi', key: 'QuestionText', minWidth: 280 },
				{ title: 'Nguồn file', key: 'sourceFileLabel', width: 150, sortable: false },
				{ title: 'Loại câu hỏi', key: 'Type', width: 170 },
				{ title: 'Mức độ', key: 'skills', width: 180, sortable: false },
				{ title: 'Điểm', key: 'Points', width: 70, align: 'center' },
				{ title: 'Thao tác', key: 'actions', sortable: false, width: 90, align: 'center' },
			],
			TypeOptions: [
				{ value: 'QUIZ_SINGLE_CHOICE', label: 'Trắc nghiệm 1 đáp án' },
				{ value: 'QUIZ_MULTIPLE_CHOICE', label: 'Trắc nghiệm nhiều đáp án' },
				{ value: 'QUIZ_TRUE_FALSE', label: 'Đúng / Sai' },
				{ value: 'QUIZ_MULTIPLE_TRUE_FALSE', label: 'Nhiều mệnh đề Đúng / Sai' },
				{ value: 'QUIZ_FILL_IN_BLANK', label: 'Điền chỗ trống' },
				{ value: 'QUIZ_MATCHING', label: 'Nối đáp án' },
				{ value: 'QUIZ_ORDERING', label: 'Sắp xếp thứ tự' },
				{ value: 'SHORT_ANSWER', label: 'Trả lời ngắn' },
				{ value: 'ESSAY', label: 'Tự luận' },
				{ value: 'FILE_UPLOAD', label: 'Nộp file' },
				{ value: 'AUDIO_RESPONSE', label: 'Ghi âm' },
			],
				// Các mức độ nhận thức là taxonomy dùng chung; riêng Tin học sẽ thay mức Vận dụng cao bằng Dạng đúng/Sai.
				// Giữ schema KyNang_* để các module cũ vẫn đọc được SkillsJson, đồng thời bổ sung mã ổn định cho ma trận đề.
			commonQuestionLevels: [
				{ KyNang_MonHoc_ChiTietID: 'cog_nhan_biet', SkillCode: 'NHAN_BIET', MucDoCode: 'NHAN_BIET', TenKyNang: 'Nhận biết', NhomKyNang: 'Mức độ nhận thức', OrdinalNumber: 1 },
				{ KyNang_MonHoc_ChiTietID: 'cog_thong_hieu', SkillCode: 'THONG_HIEU', MucDoCode: 'THONG_HIEU', TenKyNang: 'Thông hiểu', NhomKyNang: 'Mức độ nhận thức', OrdinalNumber: 2 },
				{ KyNang_MonHoc_ChiTietID: 'cog_van_dung', SkillCode: 'VAN_DUNG', MucDoCode: 'VAN_DUNG', TenKyNang: 'Vận dụng', NhomKyNang: 'Mức độ nhận thức', OrdinalNumber: 3 },
					{ KyNang_MonHoc_ChiTietID: 'cog_van_dung_cao', SkillCode: 'VAN_DUNG_CAO', MucDoCode: 'VAN_DUNG_CAO', TenKyNang: 'Vận dụng cao', NhomKyNang: 'Mức độ nhận thức', OrdinalNumber: 4 },
				],
				// Tin học không dùng Vận dụng cao trong Content Hub; nhóm Dạng đúng/Sai vẫn lưu theo schema kỹ năng để import và lọc dùng chung.
				computerQuestionLevels: [
					{ KyNang_MonHoc_ChiTietID: 'cog_dang_dung_sai', SkillCode: 'DANG_DUNG_SAI', MucDoCode: 'DANG_DUNG_SAI', TenKyNang: 'Dạng đúng/Sai', NhomKyNang: 'Dạng câu hỏi', OrdinalNumber: 4 },
				],
			DSSkill: [],
			skillsLoading: false,
			// Giữ value tương thích với lms_tc_asm_builder để dữ liệu tạo/sửa/import dùng chung schema.
			gradingTypeOptions: [
				{ value: 'auto', title: 'Tự động' },
				{ value: 'manual', title: 'Thủ công' },
			],
			// Dùng cùng taxonomy tài liệu với soan-hoc-lieu-v2 để các module phân loại tài nguyên nhất quán.
			materialTypeOptions: [
				{ value: 'VIDEO', title: 'Video', description: 'Video thường hoặc video tương tác cho Soạn bài học và Soạn bài tập', icon: 'mdi-play-circle-outline' },
				{ value: 'AUDIO', title: 'Audio', description: 'Tệp âm thanh', icon: 'mdi-volume-high' },
				{ value: 'HTML', title: 'HTML', description: 'Nội dung tương tác', icon: 'mdi-code-tags' },
				{ value: 'IMAGE', title: 'Hình ảnh', description: 'Ảnh minh họa', icon: 'mdi-image-outline' },
				{ value: 'SLIDE', title: 'PPT, DOC & PDF', description: 'Trình chiếu hoặc tài liệu', icon: 'mdi-presentation-play' },
				{ value: 'ISPRING_CONTENT', title: 'iSpring', description: 'Gói bài giảng iSpring', icon: 'mdi-play-box-multiple' },
			],
		}
	},
	computed: {
		// BGH/Admin được xem Sáng kiến của giáo viên; Tổ trưởng không có quyền ở nhánh này.
		isBGHUser() {
			const runtimeVueData = typeof window !== 'undefined' ? window.vueData : null
			const candidates = [
				this.vueData?.user, this.vueData?.userInfo, this.vueData?.UserInfo, this.vueData?.User,
				runtimeVueData?.user, runtimeVueData?.userInfo, runtimeVueData?.UserInfo, runtimeVueData?.User,
				typeof window !== 'undefined' ? window.userInfo : null,
				typeof window !== 'undefined' ? window.UserInfo : null,
				typeof window !== 'undefined' ? window.user : null,
			].filter(Boolean)
			const isManagementValue = value => {
				if (value === undefined || value === null || value === '') return false
				if (Array.isArray(value)) return value.some(item => isManagementValue(item))
				if ([3, 9].includes(Number(value))) return true
				if (typeof value !== 'string') return false
				const normalized = value.toLowerCase()
				return normalized.includes('bgh') || normalized.includes('admin') || normalized.includes('quản lý') || normalized.includes('quanly')
			}
			for (const user of candidates) {
				const rights = [user.SystemRight, user.systemRight, user.sys_SystemRight, user.SYS_SYSTEMRIGHT, user.sys_systemright, user.Role, user.role, user.VaiTro, user.vaitro, user.FunctionRight, user.functionRight, user.sys_FunctionRight, user.RoleName, user.roleName, user.VaiTroName, user.vaiTroName, user.ChucVu, user.chucVu, user.Position, user.position]
				if (rights.some(value => isManagementValue(value))) return true
			}
			return [this.vueData?.SystemRight, this.vueData?.systemRight, this.vueData?.Role, this.vueData?.role, runtimeVueData?.SystemRight, runtimeVueData?.systemRight].some(value => isManagementValue(value))
		},
		isProfileSupervisor() {
			if (this.isBGHUser) return true
			const runtimeVueData = typeof window !== 'undefined' ? window.vueData : null
			const candidates = [
				this.vueData?.user, this.vueData?.userInfo, this.vueData?.UserInfo, this.vueData?.User,
				runtimeVueData?.user, runtimeVueData?.userInfo, runtimeVueData?.UserInfo, runtimeVueData?.User,
				typeof window !== 'undefined' ? window.userInfo : null,
				typeof window !== 'undefined' ? window.UserInfo : null,
				typeof window !== 'undefined' ? window.user : null,
			].filter(Boolean)
			const isTeamLeaderValue = value => {
				if (value === undefined || value === null || value === '') return false
				if (Array.isArray(value)) return value.some(item => isTeamLeaderValue(item))
				if (Number(value) === 5) return true
				if (typeof value !== 'string') return false
				const normalized = value.toLowerCase()
				return normalized.includes('tổ trưởng') || normalized.includes('totruong')
			}
			for (const user of candidates) {
				const rights = [user.SystemRight, user.systemRight, user.sys_SystemRight, user.SYS_SYSTEMRIGHT, user.sys_systemright, user.Role, user.role, user.VaiTro, user.vaitro, user.FunctionRight, user.functionRight, user.sys_FunctionRight, user.RoleName, user.roleName, user.VaiTroName, user.vaiTroName, user.ChucVu, user.chucVu, user.Position, user.position]
				if (rights.some(value => isTeamLeaderValue(value))) return true
			}
			return [this.vueData?.SystemRight, this.vueData?.systemRight, this.vueData?.Role, this.vueData?.role, runtimeVueData?.SystemRight, runtimeVueData?.systemRight].some(value => isTeamLeaderValue(value))
		},
		isProfileInspectionMode() {
			return Boolean(this.isProfileSupervisor && this.activeBranch === 'profile' && this.profileMode === 'teachers' && this.selectedTeacherProfile)
		},
		isInitiativeInspectionMode() {
			return Boolean(this.isBGHUser && this.activeBranch === 'initiative' && this.initiativeMode === 'teachers' && this.selectedTeacherInitiative)
		},
						profileTeachers() {
							const profileLibs = this.libraries.filter(item => Number(item.KhoiID || 0) === 0 && Number(item.MonHocID || 0) === 0 && (String(item.TenHocLieu || '').trim() === 'Hồ sơ của tôi' || item.TaiNguyenLoaiCode === 'TAI_LIEU_THAM_KHAO'))
							const libMap = new Map()
							profileLibs.forEach(lib => {
								const userId = String(lib.CreateUser || lib.NguoiUploadID || '').trim()
								if (userId) libMap.set(userId.toUpperCase(), { GiaoVienID: userId, UserID: userId, FullName: lib.NguoiUploadName || userId, HocLieuID: lib.HocLieuID, fileCount: Number(lib.SoLuongFile || 0) })
			})
			if (this.assignedTeachers.length) {
				return this.assignedTeachers.map(teacher => {
					const info = libMap.get(String(teacher.UserID || '').trim().toUpperCase())
					return { GiaoVienID: teacher.GiaoVienID || teacher.UserID, UserID: teacher.UserID, FullName: teacher.FullName || info?.FullName || teacher.UserID, HocLieuID: info?.HocLieuID || null, fileCount: info?.fileCount || 0 }
				}).sort((a, b) => (b.fileCount || 0) - (a.fileCount || 0) || a.FullName.localeCompare(b.FullName))
			}
			return Array.from(libMap.values()).sort((a, b) => (b.fileCount || 0) - (a.fileCount || 0) || a.FullName.localeCompare(b.FullName))
		},
		filteredProfileTeachers() {
			const query = String(this.teacherSearchQuery || '').trim().toLowerCase()
			if (!query) return this.profileTeachers
			return this.profileTeachers.filter(teacher => String(teacher.FullName || '').toLowerCase().includes(query) || String(teacher.UserID || '').toLowerCase().includes(query))
		},
		initiativeTeachers() {
			const countMap = new Map()
			const nameMap = new Map()
			this.innovationNodes.filter(item => item.LoaiNoiDung !== 'THU_MUC').forEach(item => {
				const normalized = this.normalizeDocument(item)
				const ownerId = this.getDocumentOwnerId(item) || normalized.createdByLabel || ''
				if (!ownerId) return
				const key = String(ownerId).toUpperCase()
				countMap.set(key, (countMap.get(key) || 0) + 1)
				if (!nameMap.has(key)) nameMap.set(key, normalized.createdByLabel || ownerId)
			})
			if (this.assignedTeachers.length) {
				return this.assignedTeachers.map(teacher => {
					const key = String(teacher.UserID || '').trim().toUpperCase()
					return { GiaoVienID: teacher.GiaoVienID || teacher.UserID, UserID: teacher.UserID, FullName: teacher.FullName || nameMap.get(key) || teacher.UserID, fileCount: countMap.get(key) || 0 }
				}).sort((a, b) => (b.fileCount || 0) - (a.fileCount || 0) || a.FullName.localeCompare(b.FullName))
			}
			return Array.from(countMap.entries()).map(([key, count]) => ({ GiaoVienID: key, UserID: key, FullName: nameMap.get(key) || key, fileCount: count })).sort((a, b) => (b.fileCount || 0) - (a.fileCount || 0) || a.FullName.localeCompare(b.FullName))
		},
		filteredInitiativeTeachers() {
			const query = String(this.initiativeTeacherSearchQuery || '').trim().toLowerCase()
			if (!query) return this.initiativeTeachers
			return this.initiativeTeachers.filter(teacher => String(teacher.FullName || '').toLowerCase().includes(query) || String(teacher.UserID || '').toLowerCase().includes(query))
		},
		questionSourceOptions() {
			const map = new Map()
			this.DSQuestion.forEach(q => {
				const src = this.getQuestionSourceFile(q) || 'Chưa xác định'
				map.set(src, (map.get(src) || 0) + 1)
			})
			const options = [
				{ value: 'ALL', label: `Tất cả nguồn (${this.DSQuestion.length})` }
			]
			Array.from(map.entries()).forEach(([name, count]) => {
				options.push({ value: name, label: `${name} (${count})` })
			})
			return options
		},
		filteredDSQuestion() {
			if (!this.selectedQuestionSource || this.selectedQuestionSource === 'ALL') {
				return this.DSQuestion
			}
			return this.DSQuestion.filter(q => this.getQuestionSourceFile(q) === this.selectedQuestionSource)
		},
		isComputerSubjectContext() {
			const subjectName = this.selectedMon?.TenMonHoc_HienThi || this.selectedMon?.MonHocName || this.selectedMon?.TenMonHoc || ''
			return /tin\s*h[oọ]c|informatics|computer\s*science/i.test(String(subjectName))
		},
		isPrimarySchoolContext() {
			const selectedKhoi = this.treeKhoi.find(item => String(item?.KhoiID) === String(this.selectedMon?.KhoiID)) || {}
			// API có thể chỉ trả KhoiID; sidebar vẫn hiển thị fallback "Khối N", nên dùng cùng nhãn fallback để nhận diện Tiểu học.
			const selectedKhoiId = selectedKhoi?.KhoiID ?? this.selectedMon?.KhoiID
			const selectedKhoiDisplayName = selectedKhoi?.TenKhoiHoc || selectedKhoi?.KhoiName || (selectedKhoiId ? 'Khối ' + selectedKhoiId : '')
			const contextValues = [
				this.vueData?.CapID,
				this.vueData?.CapHocID,
				this.vueData?.CapHoc,
				this.selectedMon?.CapID,
				this.selectedMon?.CapHocID,
				this.selectedMon?.CapHoc,
				this.selectedMon?.TenCapHoc,
				this.selectedMon?.CapHocName,
				this.selectedMon?.TenKhoiHoc,
				this.selectedMon?.KhoiName,
				selectedKhoi?.CapID,
				selectedKhoi?.CapHocID,
				selectedKhoi?.CapHoc,
				selectedKhoi?.TenCapHoc,
				selectedKhoi?.CapHocName,
				selectedKhoi?.TenKhoiHoc,
				selectedKhoi?.KhoiName,
				selectedKhoiDisplayName,
			]
			// Chỉ tắt mức độ khi metadata xác định rõ Tiểu học/Cấp 1 hoặc tên khối là Khối 1–5; cấp khác vẫn dùng taxonomy.
			return contextValues.some(value => /tiểu\s*học|tieu\s*hoc|cấp\s*1|cap\s*1|primary|elementary|khối\s*[1-5]\b|khoi\s*[1-5]\b/i.test(String(value || ''))) || contextValues.some(value => Number(value) === 1 && ['1', 1].includes(value))
		},
		questionTableGroups() {
			// Tiểu học không còn phân nhóm theo mức độ; nhóm kỹ thuật duy nhất giúp tái sử dụng vòng render của bảng nhưng không hiện ra UI.
			if (this.isPrimarySchoolContext) return [{ _key: 'all', questions: this.filteredDSQuestion }]
			// Các cấp còn lại tạo group từ taxonomy của môn hiện tại trước, sau đó mới phân câu hỏi đã lọc vào từng group để cả group 0 câu vẫn hiện trên bảng.
			const groups = this.DSSkill.map(level => ({
				...level,
				_key: String(level.KyNang_MonHoc_ChiTietID || level.SkillCode || level.TenKyNang),
				questions: this.filteredDSQuestion.filter(question => {
					const questionLevel = this.getQuestionLevel(question)
					return questionLevel && String(questionLevel.KyNang_MonHoc_ChiTietID) === String(level.KyNang_MonHoc_ChiTietID)
				}),
			}))
			const unassignedQuestions = this.filteredDSQuestion.filter(question => !this.getQuestionLevel(question))
			// Đây là group hệ thống, không phải một mức độ mới trong taxonomy; câu import không có mapping sẽ tự rơi vào đây, kể cả khi count đang là 0.
			groups.push({
				_key: 'unassigned',
				TenKyNang: 'Chưa xác định mức độ',
				NhomKyNang: 'Câu hỏi chưa được gán mức độ',
				_isUnassigned: true,
				questions: unassignedQuestions,
			})
			return groups
		},
		allVisibleQuestionsSelected() {
			return this.filteredDSQuestion.length > 0 && this.filteredDSQuestion.every(question => this.isQuestionSelected(question))
		},
		someVisibleQuestionsSelected() {
			return this.filteredDSQuestion.some(question => this.isQuestionSelected(question))
		},
		innovationLibraries() {
			return this.libraries.filter(item => item.TaiNguyenLoaiCode === 'SANG_KIEN')
		},
		selectedLibrary() {
			return this.libraries.find(item => item.HocLieuID === this.selectedLibraryId) || null
		},
		selectedImportCount() {
			return this.importQuestions.filter(item => item._selected && item._supported).length
		},
		allImportQuestionsSelected() {
			const supportedCount = this.importQuestions.filter(item => item._supported).length
			return supportedCount > 0 && this.selectedImportCount === supportedCount
		},
		// Chỉ giới hạn Import JSON cho SystemRight 9; Import từ file không dùng quyền này.
		canImportQuestionJson() {
			const systemRight = this.vueData?.user?.SystemRight ?? this.vueData?.user?.systemright
			const rights = Array.isArray(systemRight) ? systemRight : [systemRight]
			return rights.some(right => Number(right) === 9)
		},
		parsedJsonImportData() {
			const text = String(this.jsonImportText || '').trim()
			if (!text) return null
			try {
				let parsed = JSON.parse(text)
				if (typeof parsed === 'string') {
					try { parsed = JSON.parse(parsed) } catch (e) {}
				}
				let row = Array.isArray(parsed) ? parsed[0] : (parsed?.data?.[0] || parsed)
				let innerData = row?.Data || row?.data || row
				if (typeof innerData === 'string') {
					try { innerData = JSON.parse(innerData) } catch (e) {}
				}
				if (typeof innerData?.data === 'string') {
					try { innerData.data = JSON.parse(innerData.data) } catch (e) {}
				}
				const questions = innerData?.data?.questions || innerData?.questions || innerData?.result?.questions || (Array.isArray(innerData) ? innerData : [])
				const filename = innerData?.filename || innerData?.data?.filename || row?.FileName || row?.filename || this.jsonImportFileName || 'Dữ liệu JSON'
				if (Array.isArray(questions) && questions.length) {
					return { filename, questions }
				}
				return null
			} catch (error) {
				return null
			}
		},
		parsedJsonImportCount() {
			return this.parsedJsonImportData?.questions?.length || 0
		},
		importDialogTitle() {
			if (this.importSourceType === 'JSON_IMPORT') return 'Import câu hỏi từ JSON'
			return this.importSourceType === 'DOCUMENT_FILE' ? 'Import câu hỏi từ file' : 'Import câu hỏi từ học liệu số'
		},
		selectedImportSkillMissingCount() {
			// Chỉ cảnh báo số câu chưa có mức độ; giữ tương thích với flow cũ vì mapping này là tùy chọn.
			if (this.isPrimarySchoolContext || !this.DSSkill.length) return 0
			return this.importQuestions.filter(item => item._selected && item._supported && !(Array.isArray(item._skillIds) && item._skillIds.length)).length
		},
		canSaveImportedQuestions() {
			// Không khóa import khi user không muốn gán kỹ năng; chỉ cần có ít nhất một câu được chọn.
			return this.selectedImportCount > 0 && !this.importSaving && !this.skillsLoading
		},
		hasRichTextEditor() {
			// FEditor gọi ClassicEditor trực tiếp; chỉ mount component khi bundle CKEditor đã có trên window.
			return typeof window !== 'undefined' && typeof window.ClassicEditor === 'function'
		},
		documentItems() {
			if (this.activeBranch === 'initiative') {
				const all = this.innovationNodes.filter(item => item.LoaiNoiDung !== 'THU_MUC').map(item => this.normalizeDocument(item))
				if (this.isInitiativeInspectionMode) {
					const targetUserId = String(this.selectedTeacherInitiative?.UserID || '').toUpperCase()
					return all.filter(item => String(this.getDocumentOwnerId(item) || '').toUpperCase() === targetUserId)
				}
				if (this.isBGHUser && this.initiativeMode === 'teachers' && !this.selectedTeacherInitiative) return []
				// Ở chế độ cá nhân, chỉ hiển thị sáng kiến do tài khoản hiện tại sở hữu.
				return all.filter(item => this.isInitiativeOwner(item))
			}
			if (this.activeBranch === 'profile') {
				if (this.profileMode === 'teachers' && !this.selectedTeacherProfile) return []
				// Hồ sơ chỉ lấy file trực tiếp trong folder hiện tại; folder con được render thành card phía trên bảng.
				return this.nodes
					.filter(item => item.LoaiNoiDung !== 'THU_MUC' && this.sameProfileParent(item.ParentID, this.profileCurrentFolderId))
					.map(item => this.normalizeDocument(item))
			}
			if (this.selectedLibraryId) {
				return this.nodes.filter(item => item.LoaiNoiDung !== 'THU_MUC').map(item => this.normalizeDocument(item))
			}
			if (this.selectedMon) {
				return this.sourceFiles
					.filter(item => Number(item.KhoiID) === Number(this.selectedMon.KhoiID) && Number(item.MonHocID) === Number(this.selectedMon.MonHocID))
					.map(item => this.normalizeDocument(item))
			}
			return []
		},
		canUploadCurrentContext() {
			if (this.isProfileInspectionMode || this.isInitiativeInspectionMode) return false
			return Boolean(this.activeBranch === 'initiative' ? this.innovationLibraries.length : (this.activeBranch === 'profile' ? this.selectedLibraryId : this.selectedMon))
		},
		profileFolderItems() {
			if (this.activeBranch !== 'profile') return []
			if (this.profileMode === 'teachers' && !this.selectedTeacherProfile) return []
			return this.nodes.filter(item => item.LoaiNoiDung === 'THU_MUC' && this.sameProfileParent(item.ParentID, this.profileCurrentFolderId))
		},
		// Map đếm số lượng file trực tiếp thuộc từng folderId (null là root) để hiển thị badge và icon trạng thái có file.
		profileDirectFileCountMap() {
			if (this.activeBranch !== 'profile') return new Map()
			const map = new Map()
			const files = this.nodes.filter(item => item.LoaiNoiDung !== 'THU_MUC')
			files.forEach(file => {
				const key = file.ParentID === null || file.ParentID === undefined || file.ParentID === '' ? null : String(file.ParentID)
				map.set(key, (map.get(key) || 0) + 1)
			})
			return map
		},
		profileFolderTree() {
			if (this.activeBranch !== 'profile') return []
			if (this.profileMode === 'teachers' && !this.selectedTeacherProfile) return []
			const folders = this.nodes.filter(item => item.LoaiNoiDung === 'THU_MUC')
			const directCountMap = this.profileDirectFileCountMap
			// Tính số file trực tiếp và đệ quy tổng số file trong toàn bộ cây con của thư mục
			const buildChildren = (parentId, ancestors = new Set()) => folders
				.filter(item => this.sameProfileParent(item.ParentID, parentId) && !ancestors.has(String(item.NoiDungID)))
				.map(item => {
					const children = buildChildren(item.NoiDungID, new Set([...ancestors, String(item.NoiDungID)]))
					const directFiles = directCountMap.get(String(item.NoiDungID)) || 0
					const totalSubFiles = children.reduce((sum, c) => sum + (c.totalFiles || 0), 0)
					const totalFiles = directFiles + totalSubFiles
					return {
						...item,
						directFiles,
						totalFiles,
						children
					}
				})
			const rootChildren = buildChildren(null)
			const rootDirectFiles = directCountMap.get(null) || 0
			const rootTotalSubFiles = rootChildren.reduce((sum, c) => sum + (c.totalFiles || 0), 0)
			const rootTotalFiles = rootDirectFiles + rootTotalSubFiles
			const rootTitle = this.isProfileInspectionMode
				? `Hồ sơ: ${this.selectedTeacherProfile.FullName || this.selectedTeacherProfile.UserID}`
				: 'Hồ sơ của tôi'
			return [{
				NoiDungID: 'profile-root',
				TenNoiDung: rootTitle,
				ParentID: null,
				LoaiNoiDung: 'PROFILE_ROOT',
				directFiles: rootDirectFiles,
				totalFiles: rootTotalFiles,
				children: rootChildren
			}]
		},
		// Dùng cùng phép đếm đệ quy của Dạng cây để thẻ có thể hiện số file trong toàn bộ nhánh folder.
		profileFolderCountMap() {
			const map = new Map()
			const visit = items => items.forEach(item => {
				if (item.NoiDungID !== 'profile-root') {
					map.set(String(item.NoiDungID), {
						directFiles: item.directFiles || 0,
						totalFiles: item.totalFiles || 0,
					})
				}
				visit(item.children || [])
			})
			visit(this.profileFolderTree)
			return map
		},
		profileCurrentFolder() {
			return this.nodes.find(item => String(item.NoiDungID) === String(this.profileCurrentFolderId)) || null
		},
		profileBreadcrumbItems() {
			const rootTitle = this.isProfileInspectionMode
				? `Hồ sơ (${this.selectedTeacherProfile?.FullName || this.selectedTeacherProfile?.UserID})`
				: 'Hồ sơ của tôi'
			const items = [{ title: rootTitle, id: null }]
			const byId = new Map(this.nodes.map(item => [String(item.NoiDungID), item]))
			const trail = []
			let current = this.profileCurrentFolder
			const visited = new Set()
			while (current && !visited.has(String(current.NoiDungID))) {
				visited.add(String(current.NoiDungID))
				trail.unshift({ title: current.TenNoiDung, id: current.NoiDungID })
				current = byId.get(String(current.ParentID)) || null
			}
			return items.concat(trail)
		},
		selectedMaterialType() {
			return this.materialTypeOptions.find(item => item.value === this.pendingUploadType) || {}
		},
		interactiveYoutubeVideoId() {
			return this.getYoutubeVideoId(this.interactiveVideoUrl)
		},
		interactiveVideoEmbedUrl() {
			if (!this.interactiveVideoUrl) return ''
			return this.interactiveVideoUrl.startsWith('http') ? this.interactiveVideoUrl : (this.vueData.v_Set?.urlReadFile || '') + this.interactiveVideoUrl
		},
		hasQuestionFormMedia() {
			return this.hasMediaObject(this.questionForm?._media)
		},
		questionMediaItems() {
			const mediaType = this.questionForm?._media?.type
			return this.documentItems.filter(item => {
				const meta = item?._meta || {}
				const kind = `${item?.LoaiNoiDung || ''} ${meta.resourceType || ''} ${meta.mediaType || ''} ${item?.contentType || ''} ${item?.displayName || ''} ${item?.fileUrl || ''}`.toLowerCase()
				if (mediaType === 'YOUTUBE') return /video|youtube|\.mp4\b|\.webm\b|\.mov\b/.test(kind)
				if (mediaType === 'RECORD_AUDIO') return /audio|\.mp3\b|\.wav\b|\.aac\b|\.m4a\b|\.ogg\b/.test(kind)
				// Tab File chỉ cho chọn ảnh hoặc tệp đính kèm có thể gắn vào câu hỏi; không đưa HTML/nội dung web vào danh sách này.
				if (/html|text\/html|\bhtml\b/.test(kind)) return false
				return /image|png|jpe?g|gif|webp|svg|bmp|pdf|docx?|xlsx?|pptx?/.test(kind)
			})
		},
		currentContextDescription() {
			if (this.activeBranch === 'initiative') {
				if (this.isInitiativeInspectionMode) return `Sáng kiến của giáo viên: ${this.selectedTeacherInitiative?.FullName || this.selectedTeacherInitiative?.UserID} (${this.selectedTeacherInitiative?.UserID}) · Chế độ giám sát BGH (Chỉ đọc).`
				return 'Kho tài nguyên Sáng kiến độc lập — bạn quản lý tài liệu của mình.'
			}
			if (this.activeBranch === 'profile') {
				if (this.isProfileInspectionMode) return `Hồ sơ của giáo viên: ${this.selectedTeacherProfile?.FullName || this.selectedTeacherProfile?.UserID} (${this.selectedTeacherProfile?.UserID}) · Chế độ giám sát (Chỉ đọc).`
				return 'Kho lưu trữ cá nhân — bạn tự tạo thư mục và sắp xếp file theo nhu cầu.'
			}
			if (this.selectedMon) return 'Nguồn dữ liệu được lọc theo Khối/Môn đang chọn.'
			return 'Chọn Khối và Môn để xem Tài liệu hoặc Ngân hàng câu hỏi.'
		},
		emptyDocumentMessage() {
			if (this.activeBranch === 'initiative') return this.isInitiativeInspectionMode ? 'Giáo viên này chưa có tài liệu Sáng kiến.' : 'Bạn chưa tải tài liệu nào vào kho Sáng kiến.'
			if (this.activeBranch === 'profile') return this.isProfileInspectionMode ? (this.profileCurrentFolderId ? 'Thư mục này của giáo viên chưa có file.' : 'Giáo viên này chưa có file trong Hồ sơ.') : (this.profileCurrentFolderId ? 'Thư mục này chưa có file.' : 'Hồ sơ chưa có file. Hãy tạo thư mục hoặc tải file lên.')
			if (this.activeBranch === 'subject' && !this.selectedMon) return 'Chọn Khối/Môn để xem tài liệu.'
			return 'Chưa có tài liệu trong context này.'
		}
	},
	watch: {
		'vueData.NienKhoa'() {
			this.syncAcademicContext()
		},
		// HocKi nằm trong object NienKhoaItem; phải theo dõi cả object để đổi học kỳ không giữ cây Khối/Môn cũ.
		'vueData.NienKhoaItem': {
			deep: true,
			handler() {
				this.syncAcademicContext()
			}
		},
		previewDialog(value) {
			if (value) this.lockPreviewScroll()
			else this.restorePreviewScroll()
		},
		uploadVideoMode(value) {
			if (value === 'INTERACTIVE' && this.interactiveVideoUrl) this.$nextTick(() => this.initInteractiveYoutubePlayer())
			if (value !== 'INTERACTIVE') this.destroyInteractiveYoutubePlayer()
		},
		interactiveVideoUrl(value) {
			if (this.uploadVideoMode !== 'INTERACTIVE') return
			if (value && this.interactiveYoutubeVideoId) this.$nextTick(() => this.initInteractiveYoutubePlayer())
			else this.destroyInteractiveYoutubePlayer()
		},
	},
	mounted() {
		this.initializePage()
	},
	beforeUnmount() {
		clearTimeout(this.questionSearchTimer)
		this.destroyInteractiveYoutubePlayer()
		this.restorePreviewScroll()
	},
		methods: {
			// Mã giáo viên là khóa chuẩn của endpoint avatar; UserID chỉ là fallback cho các nguồn dữ liệu cũ.
			teacherAvatarUrl(teacher) {
				const giaoVienId = String(teacher?.GiaoVienID || teacher?.UserID || '').trim()
				return giaoVienId ? `https://file.lhbs.vn/me/avatarOrigin/${encodeURIComponent(giaoVienId)}.jpg` : ''
			},
			teacherInitial(teacher) {
				return String(teacher?.FullName || teacher?.GiaoVienID || teacher?.UserID || '?').charAt(0).toUpperCase()
			},
			lockPreviewScroll() {
			if (typeof document === 'undefined' || this._previewScrollLocked) return
			this._previewBodyOverflow = document.body?.style?.overflow || ''
			this._previewHtmlOverflow = document.documentElement?.style?.overflow || ''
			if (document.body) document.body.style.overflow = 'hidden'
			if (document.documentElement) document.documentElement.style.overflow = 'hidden'
			this._previewScrollLocked = true
		},
		restorePreviewScroll() {
			if (typeof document === 'undefined' || !this._previewScrollLocked) return
			if (document.body) document.body.style.overflow = this._previewBodyOverflow ?? ''
			if (document.documentElement) document.documentElement.style.overflow = this._previewHtmlOverflow ?? ''
			this._previewScrollLocked = false
		},

		async initializePage() {
			this.treeLoading = true
			try {
				await Promise.all([
					this.loadResourceTypes(),
					this.loadLibraries(),
					this.loadAssignedTeachers(),
				])
				await this.syncAcademicContext()
			} finally {
				this.treeLoading = false
			}
		},
		syncAcademicContext() {
			const nienKhoa = Number(this.vueData?.NienKhoa || 0)
			const hocKi = Number(this.vueData?.NienKhoaItem?.HocKi || 0)
			if (!nienKhoa || !hocKi) {
				this.treeKhoi = []
				return Promise.resolve()
			}
			const contextKey = `${nienKhoa}:${hocKi}`
			if (contextKey === this.lastAcademicContextKey) return Promise.resolve()
			this.lastAcademicContextKey = contextKey
			this.resetSubjectContext()
			return this.loadTeacherSubjectTree()
		},
		resetSubjectContext() {
			// Đổi niên khóa/học kỳ phải xóa selection và danh sách phụ thuộc để không lưu nhầm context.
			this.selectedMon = null
			this.selectedGroup = null
			this.DSGroup = []
			this.DSQuestion = []
			this.DSSkill = []
			this.sourceFiles = []
			this.treeKhoi = []
		},
		async refreshData() {
			this.isRefreshing = true
			try {
				await Promise.all([this.loadLibraries(), this.loadAssignedTeachers(), this.loadTeacherSubjectTree(), this.selectedMon ? this.loadSourceFiles(this.selectedMon) : Promise.resolve()])
				if (this.activeBranch === 'initiative') await this.loadInnovationResources()
				else if (this.activeBranch === 'profile') {
					if (this.isProfileSupervisor && this.profileMode === 'teachers' && this.selectedTeacherProfile) {
						const refreshedTeacher = this.profileTeachers.find(teacher => teacher.UserID === this.selectedTeacherProfile.UserID)
						if (refreshedTeacher) {
							this.selectedTeacherProfile = refreshedTeacher
							this.selectedLibraryId = refreshedTeacher.HocLieuID
						}
						await this.loadTree()
					} else {
						await this.ensureProfileLibrary()
						await this.loadTree()
					}
				}
				else if (this.selectedLibraryId) await this.loadTree()
				if (this.selectedMon && this.activeSection === 'questions') await this.loadGroups()
			} finally {
				this.isRefreshing = false
			}
		},
		async loadAssignedTeachers() {
			try {
				// Ưu tiên danh sách giáo viên được phân công để BGH thấy cả giáo viên chưa có file.
				const rows = await fetchPromise('lms/GiaoVienLopAll_Get', {}, { cache: false, suppressError: true }).catch(() => [])
				const map = new Map()
				const flatRows = Array.isArray(rows) ? (Array.isArray(rows[0]) ? rows[0] : rows) : []
				flatRows.forEach(item => {
					const id = String(item.GiaoVienID || '').trim()
					if (!id || map.has(id.toUpperCase())) return
					const fullName = String(item.HoTen || item.HoTenGV || `${item.HoGV || ''} ${item.TenGV || ''}`).trim()
					map.set(id.toUpperCase(), { GiaoVienID: id, UserID: id, FullName: fullName || id })
				})
				if (!map.size) {
					const fallbackRows = await fetchPromise('lms/GiaoVien_Get', {}, { cache: false, suppressError: true }).catch(() => [])
					const flatFallback = Array.isArray(fallbackRows) ? (Array.isArray(fallbackRows[0]) ? fallbackRows[0] : fallbackRows) : []
					flatFallback.forEach(item => {
						const id = String(item.GiaoVienID || '').trim()
						if (!id || map.has(id.toUpperCase())) return
						const fullName = String(item.HoTenGV || item.HoTen || `${item.HoGV || ''} ${item.TenGV || ''}`).trim()
						map.set(id.toUpperCase(), { GiaoVienID: id, UserID: id, FullName: fullName || id })
					})
				}
				this.assignedTeachers = Array.from(map.values()).sort((a, b) => a.FullName.localeCompare(b.FullName))
			} catch (error) {
				console.warn('loadAssignedTeachers error:', error)
			}
		},
		async loadResourceTypes() {
			const result = await fetchPromise('lms/FP_TaiNguyenLoai_GetAll', {}, { cache: false })
			this.resourceTypes = result ?? []
		},
		async loadLibraries() {
			const result = await fetchPromise('lms/FP_TaiNguyen_GetAll', { KhoiID: 0, MonHocID: 0, TaiNguyenLoaiID: 0, TaiNguyenMucID: 0 }, { cache: false })
			this.libraries = result ?? []
			// Nhánh Sáng kiến không có bước chọn library; khi danh sách library về thì tải gộp toàn bộ node.
			if (this.activeBranch === 'initiative') this.loadInnovationResources()
		},
		findSubjectResourceLibrary(mon = this.selectedMon) {
			if (!mon) return null
			const candidates = this.libraries.filter(item => item.TaiNguyenLoaiCode === 'TAI_LIEU_THAM_KHAO'
				&& Number(item.KhoiID) === Number(mon.KhoiID)
				&& Number(item.MonHocID) === Number(mon.MonHocID))
			// GetTree gộp các kho TAI_LIEU_THAM_KHAO cùng Khối/Môn, nên kho của bất kỳ giáo viên nào
			// cũng có thể làm điểm neo để đọc cây tài liệu dùng chung.
			const sharedLibraryName = 'Tài liệu chia sẻ/tham khảo'
			return candidates.find(item => String(item.TenHocLieu || '').trim() === sharedLibraryName) || candidates[0] || null
		},
		findOwnedSubjectResourceLibrary(mon = this.selectedMon) {
			if (!mon) return null
			const ownerUserId = String(this.getCurrentUserId() || '').trim().toUpperCase()
			if (!ownerUserId) return null
			// Node_Save giữ quyền ghi theo chủ bộ tài nguyên; upload phải dùng kho riêng của giáo viên,
			// dù cây hiển thị vẫn gộp nội dung của cả Khối/Môn.
			return this.libraries.find(item => item.TaiNguyenLoaiCode === 'TAI_LIEU_THAM_KHAO'
				&& Number(item.KhoiID) === Number(mon.KhoiID)
				&& Number(item.MonHocID) === Number(mon.MonHocID)
				&& String(item.CreateUser || item.NguoiUploadID || '').trim().toUpperCase() === ownerUserId) || null
		},
		async loadSourceFiles(mon = this.selectedMon) {
			if (!mon) {
				this.sourceFiles = []
				return
			}
			// SP hỗ trợ lọc theo @KhoiID/@MonHocID; truyền context xuống server thay vì lấy toàn bộ rồi lọc ở computed.
			const result = await fetchPromise('lms/FP_TaiNguyen_SourceFile_GetAll', { KhoiID: mon.KhoiID, MonHocID: mon.MonHocID }, { forceRefresh: true, useStaleCacheOnError: false })
			this.sourceFiles = result ?? []
		},
		async loadTeacherSubjectTree() {
			const nienKhoa = Number(this.vueData?.NienKhoa || 0)
			const hocKi = Number(this.vueData?.NienKhoaItem?.HocKi || 0)
			if (!nienKhoa || !hocKi) {
				this.treeKhoi = []
				return
			}
			// Refresh gọi lại API và dựng object Khối mới, nên phải lưu trạng thái mở trước khi thay mảng;
			// nếu không, cây sẽ luôn bị thu gọn dù người dùng vẫn đang ở đúng Khối/Môn cũ.
			const openKhoiIds = new Set(this.treeKhoi.filter(item => item?._open).map(item => String(item.KhoiID)))
			const selectedKhoiId = this.selectedMon?.KhoiID
			const selectedMonId = this.selectedMon?.MonHocID
			const result = await fetchPromise('lms/EL_Teacher_GetKhoi_MonHoc_ByGiaoVienID', {
				NienKhoa: nienKhoa,
				HocKi: hocKi,
			}, { forceRefresh: true, useStaleCacheOnError: false })
			const khoiMap = {}
			;(result?.[0] || []).forEach(khoi => {
				const khoiId = String(khoi.KhoiID)
				khoiMap[khoi.KhoiID] = { ...khoi, _open: openKhoiIds.has(khoiId) || khoiId === String(selectedKhoiId || ''), children: [] }
			})
			;(result?.[1] || []).forEach(mon => { if (khoiMap[mon.KhoiID]) khoiMap[mon.KhoiID].children.push({ ...mon }) })
			this.treeKhoi = Object.values(khoiMap)
			// Trỏ lại selectedMon vào record mới để giữ đúng tên/metadata sau refresh,
			// đồng thời vẫn giữ selection nếu API trả về cùng Khối/Môn.
			if (selectedKhoiId !== null && selectedMonId !== null) {
				const refreshedMon = this.treeKhoi.flatMap(khoi => khoi.children || []).find(mon => String(mon.KhoiID) === String(selectedKhoiId) && String(mon.MonHocID) === String(selectedMonId))
				if (refreshedMon) this.selectedMon = refreshedMon
			}
		},
		toggleKhoi(khoi) {
			khoi._open = !khoi._open
		},
		async selectProfileMode(mode) {
			// Tổ trưởng được xem Hồ sơ giáo viên; các role khác không được tự chuyển sang chế độ giám sát này.
			if (mode === 'teachers' && !this.isProfileSupervisor) mode = 'personal'
			const contextRequestId = ++this.profileContextRequestId
			this.treeLoadRequestId += 1
			this.profileMode = mode
			this.profileCurrentFolderId = null
			this.profileActivatedTreeNodeIds = ['profile-root']
			// Xóa cây và library ID trước khi nạp để folder của chủ sở hữu trước không lóe lên ở chế độ mới.
			this.nodes = []
			this.selectedLibraryId = null
			if (mode === 'personal') {
				this.selectedTeacherProfile = null
				this.profileLoading = true
				try {
					await this.ensureProfileLibrary(contextRequestId)
					if (contextRequestId === this.profileContextRequestId && this.activeBranch === 'profile' && this.profileMode === 'personal') await this.loadTree()
				} catch (error) {
					this.notify(error?.message || 'Không thể mở Hồ sơ cá nhân.', 'error')
				} finally {
					this.profileLoading = false
				}
			} else if (mode === 'teachers') {
				if (this.selectedTeacherProfile) await this.selectTeacherProfile(this.selectedTeacherProfile)
				else if (this.profileTeachers.length) await this.selectTeacherProfile(this.profileTeachers[0])
				else this.nodes = []
			}
		},
		async selectTeacherProfile(teacher) {
			if (!teacher) return
			this.profileContextRequestId += 1
			this.treeLoadRequestId += 1
			// Bỏ cây đang xem ngay khi đổi giáo viên, không giữ folder của người trước trong lúc chờ API.
			this.nodes = []
			this.selectedTeacherProfile = teacher
			this.selectedLibraryId = teacher.HocLieuID || null
			this.profileCurrentFolderId = null
			this.profileActivatedTreeNodeIds = ['profile-root']
			if (!teacher.HocLieuID) {
				this.nodes = []
				return
			}
			this.profileLoading = true
			try {
				await this.loadTree()
			} catch (error) {
				this.notify(error?.message || 'Không thể tải hồ sơ của giáo viên.', 'error')
			} finally {
				this.profileLoading = false
			}
		},
		async selectInitiativeMode(mode) {
			// Khác với Hồ sơ, chỉ BGH/Admin được xem Sáng kiến của giáo viên.
			if (mode === 'teachers' && !this.isBGHUser) mode = 'personal'
			this.initiativeMode = mode
			if (mode === 'personal') {
				this.selectedTeacherInitiative = null
				await this.loadInnovationResources()
			} else if (mode === 'teachers') {
				await this.loadInnovationResources()
				if (this.selectedTeacherInitiative) {
					const refreshed = this.initiativeTeachers.find(teacher => teacher.UserID === this.selectedTeacherInitiative.UserID)
					if (refreshed) this.selectedTeacherInitiative = refreshed
					else if (this.initiativeTeachers.length) this.selectedTeacherInitiative = this.initiativeTeachers[0]
				} else if (this.initiativeTeachers.length) {
					this.selectedTeacherInitiative = this.initiativeTeachers[0]
				}
			}
		},
		selectTeacherInitiative(teacher) {
			if (!teacher) return
			this.selectedTeacherInitiative = teacher
		},
		async selectBranch(branch) {
			// Đổi nhánh phải reset source/group selection để không dùng nhầm context khác nghiệp vụ.
			const contextRequestId = ++this.profileContextRequestId
			this.treeLoadRequestId += 1
			this.activeBranch = branch
			this.activeSection = 'documents'
			this.selectedMon = null
			this.selectedGroup = null
			this.DSGroup = []
			this.DSQuestion = []
			this.selectedQuestionSource = 'ALL'
			this.selectedLibraryId = null
			this.profileCurrentFolderId = null
			this.profileActivatedTreeNodeIds = ['profile-root']
			this.selectedTreeNode = { kind: branch === 'initiative' ? 'innovation-root' : (branch === 'profile' ? 'profile-root' : 'subject-root') }
			this.nodes = []
			this.innovationNodes = []
			if (branch === 'initiative') {
				await this.loadInnovationResources()
				if (this.isBGHUser && this.initiativeMode === 'teachers' && !this.selectedTeacherInitiative && this.initiativeTeachers.length) this.selectedTeacherInitiative = this.initiativeTeachers[0]
			}
			if (branch === 'profile') {
				this.profileLoading = true
				try {
					if (this.isProfileSupervisor && this.profileMode === 'teachers') {
						if (this.selectedTeacherProfile) await this.selectTeacherProfile(this.selectedTeacherProfile)
						else if (this.profileTeachers.length) await this.selectTeacherProfile(this.profileTeachers[0])
						else this.nodes = []
					} else {
						// Kho Hồ sơ được tạo một lần theo user; sau đó chỉ đọc cây node của chính kho này.
						await this.ensureProfileLibrary(contextRequestId)
						if (contextRequestId === this.profileContextRequestId && this.activeBranch === 'profile' && this.profileMode === 'personal') await this.loadTree()
					}
				} catch (error) {
					this.notify(error?.message || 'Không thể mở Hồ sơ cá nhân.', 'error')
				} finally {
					this.profileLoading = false
				}
			}
		},
		async selectMonHoc(mon) {
			// Mọi list câu hỏi/tài liệu phụ thuộc Khối/Môn đều được xóa selection trước khi tải lại.
			this.activeBranch = 'subject'
			this.selectedMon = mon
			// Content Hub lưu tài liệu riêng trong kho TAI_LIEU_THAM_KHAO; phải chọn đúng kho trước khi loadTree,
			// nếu không documentItems sẽ chỉ đọc SourceFile của Lesson/Assignment và bỏ trống tài liệu vừa upload.
			const subjectLibrary = this.findSubjectResourceLibrary(mon)
			this.selectedLibraryId = subjectLibrary?.HocLieuID || null
			this.selectedTreeNode = { kind: 'subject', KhoiID: mon.KhoiID, MonHocID: mon.MonHocID, label: mon.TenMonHoc_HienThi || mon.MonHocName }
			this.nodes = []
			this.selectedGroup = null
			this.DSGroup = []
			this.DSQuestion = []
			// loadGroups xử lý luôn việc tạo/chọn nhóm mặc định rồi mới tải câu hỏi để tránh request đầu tiên chạy với GroupId = NULL.
			// Tải cả SourceFile dùng chung và cây kho Content Hub; documentItems ưu tiên cây kho khi đã xác định được library.
			await Promise.all([
				this.loadGroups(),
				this.loadSkills(mon.MonHocID),
				this.loadSourceFiles(mon),
				this.selectedLibraryId ? this.loadTree() : Promise.resolve(),
			])
		},
		async loadSkills() {
			this.skillsLoading = true
			try {
				// Quy ước mới của Tiểu học không còn mức độ; để DSSkill rỗng giúp toàn bộ form/import không tạo mapping cũ.
				if (this.isPrimarySchoolContext) {
					this.DSSkill = []
					return
				}
				// Không gọi EL_KyNang_MonHoc_* ở đây: Content Hub dùng taxonomy ổn định để import, lọc và đưa vào ma trận đề.
				// Riêng Tin học bỏ Vận dụng cao và thêm Dạng đúng/Sai theo quy ước của khối môn.
				const levels = this.isComputerSubjectContext
					? [...this.commonQuestionLevels.filter(level => level.MucDoCode !== 'VAN_DUNG_CAO'), ...this.computerQuestionLevels]
					: this.commonQuestionLevels
				this.DSSkill = levels.map(level => ({ ...level }))
			} finally { this.skillsLoading = false }
		},
		selectLibrary(library) {
			this.activeBranch = 'initiative'
			this.activeSection = 'documents'
			this.selectedLibraryId = library.HocLieuID
			this.selectedTreeNode = { kind: 'innovation-library', label: library.TenHocLieu }
			this.nodes = []
			this.loadTree()
		},
		async loadTree() {
			const requestId = ++this.treeLoadRequestId
			const libraryId = this.selectedLibraryId
			if (!libraryId) {
				this.nodes = []
				return
			}
			const result = await fetchPromise('lms/FP_TaiNguyen_GetTree', { HocLieuID: libraryId }, { forceRefresh: true })
			// Chỉ áp dụng kết quả nếu vẫn là request mới nhất cho đúng library đang được chọn.
			if (requestId !== this.treeLoadRequestId || String(this.selectedLibraryId || '') !== String(libraryId)) return
			this.nodes = result ?? []
		},
		async ensureProfileLibrary(contextRequestId) {
			const ownerUserId = this.getCurrentUserId()
			if (!ownerUserId) throw new Error('Không xác định được tài khoản để mở Hồ sơ cá nhân.')
			const profileName = 'Hồ sơ của tôi'
			const isCurrentUsersProfileLibrary = item => Boolean(item
				&& Number(item.KhoiID || 0) === 0
				&& Number(item.MonHocID || 0) === 0
				&& String(item.TenHocLieu || '').trim() === profileName
				&& String(item.CreateUser || item.NguoiUploadID || '').trim().toUpperCase() === ownerUserId.toUpperCase())
			const canSelectPersonalLibrary = () => this.activeBranch === 'profile'
				&& this.profileMode === 'personal'
				&& (contextRequestId === undefined || contextRequestId === this.profileContextRequestId)
			const selectedLibrary = this.libraries.find(item => String(item.HocLieuID) === String(this.selectedLibraryId || ''))
			// Không tái sử dụng selectedLibraryId nếu nó đang trỏ tới Hồ sơ của giáo viên đang được giám sát.
			if (canSelectPersonalLibrary() && isCurrentUsersProfileLibrary(selectedLibrary)) return selectedLibrary.HocLieuID
			const existing = this.libraries.find(isCurrentUsersProfileLibrary)
			if (existing?.HocLieuID) {
				if (canSelectPersonalLibrary()) this.selectedLibraryId = existing.HocLieuID
				return existing.HocLieuID
			}
			const typeInfo = this.resourceTypes.find(item => (item.TaiNguyenLoaiCode || item.Code) === 'TAI_LIEU_THAM_KHAO')
			const result = await fetchPromise('lms/FP_TaiNguyen_Save', {
				HocLieuID: 0,
				TenHocLieu: profileName,
				KhoiID: 0,
				MonHocID: 0,
				// Để null khi danh mục chưa tải kịp; SP sẽ tự resolve Code TAI_LIEU_THAM_KHAO thay vì phụ thuộc ID cứng.
				TaiNguyenLoaiID: typeInfo?.TaiNguyenLoaiID || null,
				TaiNguyenMucID: null,
				HocKy: null,
				TinhTrang: 'Private',
				ThumbnailURL: null,
			}, { cache: false })
			const candidates = Array.isArray(result?.data) ? result.data.flat(Infinity) : (Array.isArray(result) ? result.flat(Infinity) : [result])
			const created = candidates.find(item => item?.HocLieuID) || null
			await this.loadLibraries()
			const library = created?.HocLieuID
				? created
				: this.libraries.find(isCurrentUsersProfileLibrary)
			if (!library?.HocLieuID) throw new Error('Không tạo được kho Hồ sơ cá nhân.')
			if (canSelectPersonalLibrary()) this.selectedLibraryId = library.HocLieuID
			return library.HocLieuID
		},
		sameProfileParent(parentId, folderId) {
			return (parentId === null || parentId === undefined || parentId === '' ? null : String(parentId)) === (folderId === null || folderId === undefined || folderId === '' ? null : String(folderId))
		},
		getProfileFolderDirectFileCount(folderId) {
			const key = folderId === 'profile-root' || folderId === null || folderId === undefined || folderId === '' ? null : String(folderId)
			return this.profileDirectFileCountMap.get(key) || 0
		},
		getProfileFolderCounts(folderId) {
			return this.profileFolderCountMap.get(String(folderId)) || {
				directFiles: this.getProfileFolderDirectFileCount(folderId),
				totalFiles: this.getProfileFolderDirectFileCount(folderId),
			}
		},
		getProfileFolderCardIcon(folderId) {
			const counts = this.getProfileFolderCounts(folderId)
			if (counts.directFiles > 0) return 'mdi-folder-text'
			return counts.totalFiles > 0 ? 'mdi-folder' : 'mdi-folder-outline'
		},
		getProfileFolderCardCountLabel(folderId) {
			const counts = this.getProfileFolderCounts(folderId)
			return counts.totalFiles > counts.directFiles
				? counts.directFiles + '/' + counts.totalFiles + ' file'
				: counts.totalFiles + ' file'
		},
		getProfileFolderCardCountTitle(folderId) {
			const counts = this.getProfileFolderCounts(folderId)
			return counts.totalFiles > counts.directFiles
				? counts.directFiles + ' file trực tiếp · ' + counts.totalFiles + ' file trong toàn nhánh'
				: counts.totalFiles + ' file'
		},
		enterProfileFolder(folder) {
			if (!folder?.NoiDungID) return
			this.openProfileFolderById(folder.NoiDungID)
		},
		openProfileFolderById(folderId) {
			const normalizedFolderId = folderId === 'profile-root' ? null : (folderId || null)
			this.profileCurrentFolderId = normalizedFolderId
			this.profileActivatedTreeNodeIds = [normalizedFolderId || 'profile-root']
		},
		onProfileTreeActivated(ids) {
			const folderId = Array.isArray(ids) ? ids[0] : ids
			this.openProfileFolderById(folderId)
		},
		openCreateProfileFolder() {
			if (this.isProfileInspectionMode) return this.notify('Chế độ giám sát chỉ cho phép xem.', 'warning')
			if (!this.canUploadCurrentContext) return this.notify('Hồ sơ cá nhân chưa sẵn sàng. Vui lòng thử lại.', 'warning')
			this.profileEditingFolderId = null
			this.profileFolderForm = { name: '' }
			this.dialogProfileFolder = true
		},
		openEditProfileFolder(folder) {
			if (this.isProfileInspectionMode) return this.notify('Chế độ giám sát chỉ cho phép xem.', 'warning')
			if (!folder?.NoiDungID || folder.NoiDungID === 'profile-root') return
			// Dùng cùng dialog với luồng tạo mới để tên folder được cập nhật qua đúng API Node_Save.
			this.profileEditingFolderId = folder.NoiDungID
			this.profileFolderForm = { name: String(folder.TenNoiDung || '') }
			this.dialogProfileFolder = true
		},
		async saveProfileFolder() {
			if (this.isProfileInspectionMode) return this.notify('Chế độ giám sát chỉ cho phép xem.', 'warning')
			const name = String(this.profileFolderForm?.name || '').trim()
			if (!name) return this.notify('Vui lòng nhập tên thư mục.', 'warning')
			if (name.length > 500) return this.notify('Tên thư mục không được vượt quá 500 ký tự.', 'warning')
			const editingFolder = this.profileEditingFolderId
				? this.nodes.find(item => String(item.NoiDungID) === String(this.profileEditingFolderId) && item.LoaiNoiDung === 'THU_MUC')
				: null
			if (this.profileEditingFolderId && !editingFolder) return this.notify('Không tìm thấy thư mục cần sửa. Vui lòng tải lại dữ liệu.', 'warning')
			// Khi sửa từ dạng cây, folder đang chọn có thể nằm ngoài folder hiện tại; kiểm tra trùng theo đúng parent của node đó.
			const targetParentId = editingFolder ? editingFolder.ParentID : this.profileCurrentFolderId
			const siblingFolders = this.nodes.filter(item => item.LoaiNoiDung === 'THU_MUC'
				&& this.sameProfileParent(item.ParentID, targetParentId)
				&& String(item.NoiDungID) !== String(this.profileEditingFolderId || ''))
			if (siblingFolders.some(item => String(item.TenNoiDung || '').trim().toLowerCase() === name.toLowerCase())) return this.notify('Thư mục cùng tên đã tồn tại ở vị trí này.', 'warning')
			this.savingProfileFolder = true
			try {
				await this.ensureProfileLibrary()
				const folderMetadata = editingFolder
					? this.getMeta(editingFolder)
					: { origin: 'CONTENT_HUB', resourceType: 'PROFILE_FOLDER', visibilityScope: 'OWNER_ONLY' }
				await fetchPromise('lms/FP_TaiNguyen_Node_Save', {
					NoiDungID: editingFolder?.NoiDungID || 0,
					HocLieuID: this.selectedLibraryId,
					ParentID: targetParentId,
					TenNoiDung: name,
					LoaiNoiDung: editingFolder?.LoaiNoiDung || 'THU_MUC',
					ThuTu: editingFolder?.ThuTu ?? this.profileFolderItems.length,
					DataJson: JSON.stringify(folderMetadata),
					NguonTaiNguyenCode: editingFolder?.NguonTaiNguyenCode || 'CONTENT_HUB',
					NguonResourceType: editingFolder?.NguonResourceType || 'PROFILE_FOLDER',
					NguonResourceID: editingFolder?.NguonResourceID || null,
				}, { cache: false })
				this.dialogProfileFolder = false
				this.profileEditingFolderId = null
				await this.loadTree()
				this.notify(editingFolder ? 'Đã đổi tên thư mục.' : 'Đã tạo thư mục mới.')
			} catch (error) {
				this.notify(error?.message || 'Không thể tạo thư mục.', 'error')
			} finally {
				this.savingProfileFolder = false
			}
		},
		getProfileFolderDeleteImpact(folder) {
			if (!folder?.NoiDungID) return { folderPaths: [], filePaths: [], folderCount: 0, fileCount: 0, hasContent: false }
			const childrenByParent = new Map()
			this.nodes.forEach(node => {
				const parentKey = node.ParentID === null || node.ParentID === undefined || node.ParentID === '' ? null : String(node.ParentID)
				if (!childrenByParent.has(parentKey)) childrenByParent.set(parentKey, [])
				childrenByParent.get(parentKey).push(node)
			})
			// Duyệt đúng toàn bộ nhánh con, có visited để dữ liệu cây lỗi liên kết vòng không làm treo dialog xác nhận.
			const queue = [{ node: folder, path: String(folder.TenNoiDung || 'Thư mục') }]
			const visited = new Set([String(folder.NoiDungID)])
			const folderPaths = []
			const filePaths = []
			for (let index = 0; index < queue.length; index++) {
				const current = queue[index]
				const childKey = String(current.node.NoiDungID)
				const children = childrenByParent.get(childKey) || []
				children.forEach(child => {
					const childId = String(child.NoiDungID)
					if (visited.has(childId)) return
					visited.add(childId)
					const childName = child.TenNoiDung || child.FileName || 'Nội dung không tên'
					const childPath = current.path + ' / ' + childName
					if (child.LoaiNoiDung === 'THU_MUC') {
						folderPaths.push(childPath)
						queue.push({ node: child, path: childPath })
					} else {
						filePaths.push(childPath)
					}
				})
			}
			return {
				folderPaths,
				filePaths,
				folderCount: folderPaths.length,
				fileCount: filePaths.length,
				hasContent: folderPaths.length > 0 || filePaths.length > 0,
			}
		},
		formatProfileFolderDeleteWarning(folder, impact) {
			if (!impact.hasContent) return 'Thư mục "' + (folder.TenNoiDung || '') + '" đang rỗng. Bạn có chắc muốn xóa?'
			const summary = 'Nếu xóa thư mục "' + (folder.TenNoiDung || '') + '", toàn bộ nội dung bên trong cũng sẽ bị mất: ' + impact.folderCount + ' folder con và ' + impact.fileCount + ' file.'
			const details = []
			if (impact.folderPaths.length) details.push('Folder con: ' + impact.folderPaths.join(' · ') + '.')
			if (impact.filePaths.length) details.push('File: ' + impact.filePaths.join(' · ') + '.')
			return [summary].concat(details).join(' ')
		},
		async deleteProfileNode(folder) {
			if (this.isProfileInspectionMode) return this.notify('Chế độ giám sát chỉ cho phép xem.', 'warning')
			if (!folder?.NoiDungID || folder.NoiDungID === 'profile-root' || this.deletingDocumentId) return
			const impact = this.getProfileFolderDeleteImpact(folder)
			const ok = await this.confirmRef?.value?.show?.({
				title: 'Xác nhận xóa thư mục',
				text: this.formatProfileFolderDeleteWarning(folder, impact),
				type: impact.hasContent ? 'warning' : 'confirm',
				confirmText: 'Xóa thư mục',
				cancelText: 'Hủy',
				maxWidth: 600,
			})
			if (!ok) return
			this.deletingDocumentId = folder.NoiDungID
			try {
				await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: folder.NoiDungID, User: this.vueData.user?.UserID }, { cache: false })
				if (this.profileCurrentFolderId && this.isProfileDescendant(this.profileCurrentFolderId, folder.NoiDungID)) this.openProfileFolderById(folder.ParentID || null)
				await this.loadTree()
				this.notify('Đã xóa thư mục và nội dung bên trong.')
			} catch (error) {
				this.notify(error?.message || 'Không thể xóa thư mục.', 'error')
			} finally {
				this.deletingDocumentId = null
			}
		},
		isProfileDescendant(nodeId, ancestorId) {
			const byId = new Map(this.nodes.map(item => [String(item.NoiDungID), item]))
			const visited = new Set()
			let current = byId.get(String(nodeId))
			while (current && !visited.has(String(current.NoiDungID))) {
				if (String(current.NoiDungID) === String(ancestorId)) return true
				visited.add(String(current.NoiDungID))
				current = byId.get(String(current.ParentID))
			}
			return false
		},
		async loadInnovationResources() {
			if (this.activeBranch !== 'initiative') return
			const libraries = this.innovationLibraries
			if (!libraries.length) {
				this.innovationNodes = []
				return
			}
			this.innovationLoading = true
			try {
				const results = await Promise.all(libraries.map(library => fetchPromise('lms/FP_TaiNguyen_GetTree', { HocLieuID: library.HocLieuID }, { forceRefresh: true })))
				this.innovationNodes = results.flatMap((result, index) => (result || []).map(node => ({ ...node, _innovationLibraryId: libraries[index].HocLieuID, _innovationLibraryName: libraries[index].TenHocLieu })))
			} finally {
				this.innovationLoading = false
			}
		},
		async loadGroups(targetGroupId = null, targetSourceId = null) {
			if (!this.selectedMon) return
			const loadSeq = ++this.groupsLoadSeq
			const result = await fetchPromise('lms/EL_QuestionGroup_List', {
				MonHocID: this.selectedMon.MonHocID,
				KhoiID: this.selectedMon.KhoiID,
				IncludeDeleted: false,
				PageNumber: 1,
				PageSize: 100,
			}, { forceRefresh: true, useStaleCacheOnError: false })
			if (loadSeq !== this.groupsLoadSeq) return
			const previousSelectedGroupId = this.selectedGroup?.Id || null
			const groups = Array.isArray(result?.[0]) ? result[0] : (result || [])
			// Nhóm AUTO_UNASSIGNED là dữ liệu kỹ thuật của flow cũ, không được xem là nhóm người dùng đã tạo.
			this.DSGroup = groups.filter(item => !this.isTechnicalQuestionGroup(item))
			this.unassignedGroupId = null
			this.selectedGroup = null
			// Tự động chọn nhóm: ưu tiên nhóm vừa tạo/cập nhật, sau đó mới giữ nhóm cũ hoặc chọn nhóm duy nhất.
			this.selectedGroup = (targetGroupId && this.DSGroup.find(item => String(item.Id) === String(targetGroupId)))
				|| (targetSourceId && this.DSGroup.find(item => String(item.SourceId || '') === String(targetSourceId)))
				|| (previousSelectedGroupId && this.DSGroup.find(item => String(item.Id) === String(previousSelectedGroupId)))
				|| (this.DSGroup.length === 1 ? this.DSGroup[0] : null)
			await this.loadQuestions()
		},
		isTechnicalQuestionGroup(group) {
			return /^AUTO_UNASSIGNED_/i.test(String(group?.SourceId || ''))
				|| String(group?.Description || '').toLowerCase().includes('nhóm kỹ thuật tự tạo')
		},
		async ensureQuestionGroup() {
			if (this.selectedGroup?.Id) return this.selectedGroup.Id
			throw new Error('Vui lòng tạo và chọn nhóm câu hỏi trước.')
		},
		async selectGroup(group) {
			if (this.isTechnicalQuestionGroup(group)) return this.notify('Vui lòng tạo và chọn nhóm câu hỏi riêng.', 'warning')
			this.selectedGroup = group
			this.groupDrawer = false
			// Không giữ danh sách cũ trong lúc đổi group; loadQuestions sẽ bật trạng thái loading để table phản hồi ngay.
			this.DSQuestion = []
			this.expandedQuestionLevels = {}
			this.selectedQuestions = []
			this.updatedQuestionIds = []
			this.selectedQuestionSource = 'ALL'
			this.searchQ = ''
			await this.loadQuestions()
		},
		getQuestionTableWrapper() {
			return this.$refs.questionTableRef?.$el?.querySelector?.('.v-table__wrapper')
				|| this.$el?.querySelector?.('.content-hub-question-table .v-table__wrapper')
				|| document.querySelector('.content-hub-question-table .v-table__wrapper')
				|| null
		},
		questionSelectionKey(question) {
			return String(question?.Id ?? question?.ID ?? question?.id ?? '')
		},
		isQuestionSelected(question) {
			const key = this.questionSelectionKey(question)
			return Boolean(key) && this.selectedQuestions.some(selected => this.questionSelectionKey(selected) === key)
		},
		isQuestionGroupFullySelected(level) {
			return level.questions.length > 0 && level.questions.every(question => this.isQuestionSelected(question))
		},
		isQuestionGroupPartiallySelected(level) {
			if (!level.questions.length) return false
			const selectedCount = level.questions.filter(question => this.isQuestionSelected(question)).length
			return selectedCount > 0 && selectedCount < level.questions.length
		},
		toggleQuestionGroupSelection(level, selected) {
			const groupKeys = new Set(level.questions.map(question => this.questionSelectionKey(question)))
			if (selected) {
				const selectedKeys = new Set(this.selectedQuestions.map(question => this.questionSelectionKey(question)))
				this.selectedQuestions = [...this.selectedQuestions, ...level.questions.filter(question => !selectedKeys.has(this.questionSelectionKey(question)))]
			} else {
				this.selectedQuestions = this.selectedQuestions.filter(question => !groupKeys.has(this.questionSelectionKey(question)))
			}
		},
		toggleQuestionSelection(question, selected) {
			const key = this.questionSelectionKey(question)
			if (!key) return
			if (selected && !this.isQuestionSelected(question)) {
				this.selectedQuestions = [...this.selectedQuestions, question]
			} else if (!selected) {
				this.selectedQuestions = this.selectedQuestions.filter(item => this.questionSelectionKey(item) !== key)
			}
		},
		toggleAllQuestionSelection(selected) {
			const visibleKeys = new Set(this.filteredDSQuestion.map(question => this.questionSelectionKey(question)))
			if (selected) {
				const selectedKeys = new Set(this.selectedQuestions.map(question => this.questionSelectionKey(question)))
				this.selectedQuestions = [...this.selectedQuestions, ...this.filteredDSQuestion.filter(question => !selectedKeys.has(this.questionSelectionKey(question)))]
			} else {
				this.selectedQuestions = this.selectedQuestions.filter(question => !visibleKeys.has(this.questionSelectionKey(question)))
			}
		},
		getQuestionTableIndex(question) {
			const key = this.questionSelectionKey(question)
			const index = this.filteredDSQuestion.findIndex(item => this.questionSelectionKey(item) === key)
			return index >= 0 ? index + 1 : '—'
		},
		isQuestionLevelExpanded(level) {
			// Group 0 câu không có nội dung để mở; chỉ mở sẵn group có dữ liệu để giảm chiều cao rỗng của table.
			return level.questions.length > 0 && this.expandedQuestionLevels[level._key] !== false
		},
		toggleQuestionLevel(level) {
			if (!level.questions.length) return
			this.expandedQuestionLevels = {
				...this.expandedQuestionLevels,
				[level._key]: !this.isQuestionLevelExpanded(level),
			}
		},
		getQuestionRowClass(question) {
			const classes = []
			if (String(this.questionSelectionKey(question)) === String(this.highlightedQuestionId)) classes.push('question-row-highlighted')
			if (this.isQuestionMissingAnswer(question)) classes.push('question-row-no-answer')
			return classes
		},
		getQuestionRowStyle(question) {
			if (String(this.questionSelectionKey(question)) !== String(this.highlightedQuestionId)) return undefined
			const isBright = this.highlightPhase === 'bright'
			return {
				backgroundColor: isBright ? '#bbf7d0' : 'transparent',
				transition: isBright ? 'none' : 'background-color 3s ease-out',
			}
		},
		// Hiệu ứng nhận diện dòng câu hỏi vừa cập nhật thành công:
		// Giai đoạn 1 (0-400ms): Giữ màu nền xanh nổi bật (#bbf7d0) khi modal vừa đóng.
		// Giai đoạn 2 (400ms-3500ms): Kích hoạt transition mượt mà để màu nền dần trở về màu gốc của bảng.
		highlightQuestionRow(id) {
			const targetId = String(id || '')
			if (!targetId) return
			if (this.highlightQuestionTimer) clearTimeout(this.highlightQuestionTimer)
			if (this.highlightQuestionFadeTimer) clearTimeout(this.highlightQuestionFadeTimer)
			this.highlightedQuestionId = targetId
			this.highlightPhase = 'bright'
			this.highlightQuestionFadeTimer = setTimeout(() => {
				if (this.highlightedQuestionId === targetId) {
					this.highlightPhase = 'fade'
				}
			}, 400)
			this.highlightQuestionTimer = setTimeout(() => {
				if (this.highlightedQuestionId === targetId) {
					this.highlightedQuestionId = null
					this.highlightPhase = null
				}
			}, 3500)
		},
		// Kiểm tra câu hỏi tự động chấm/trắc nghiệm có bị thiếu đáp án đúng hay không
		isQuestionMissingAnswer(question) {
			if (!question) return false
			const type = question?.Type || question?.type || ''
			// Các loại câu hỏi tự luận/ghi âm/nộp file do giáo viên chấm tay nên không bắt buộc có đáp án tự động
			const manualGradingTypes = ['ESSAY', 'SHORT_ANSWER', 'FILE_UPLOAD', 'AUDIO_RESPONSE']
			if (manualGradingTypes.includes(type)) return false
			if (type === 'QUIZ_ORDERING') {
				const config = this.getQuestionConfig(question)
				const items = Array.isArray(config.items) ? config.items : []
				const itemIds = items.map(item => String(item?.id ?? ''))
				const correctOrder = Array.isArray(config.correctOrder) ? config.correctOrder.map(id => String(id)) : []
				return items.length < 2
					|| itemIds.some(id => !id)
					|| items.some(item => !this.normalizeQuestionFieldText(item?.text || '').trim())
					|| correctOrder.length !== items.length
					|| new Set(correctOrder).size !== items.length
					|| correctOrder.some(id => !itemIds.includes(id))
			}
			const answers = this.getQuestionAnswerItems(question)
			return !answers || answers.length === 0
		},
		async loadQuestions(options = {}) {
			const { silent = false, preserveScroll = true } = typeof options === 'object' && options !== null ? options : {}
			const loadSeq = ++this.questionsLoadSeq
			if (!silent) this.questionsLoading = true
			if (!this.selectedMon || !this.selectedGroup?.Id) {
				this.DSQuestion = []
				this.questionsLoading = false
				return
			}
			const wrapper = preserveScroll ? this.getQuestionTableWrapper() : null
			const savedScrollTop = wrapper ? wrapper.scrollTop : 0
			// SP dùng NULL để truy vấn toàn bộ ngân hàng; 0 là một GroupId cụ thể và sẽ làm mất danh sách.
			const groupId = this.selectedGroup?.Id || null
			const search = String(this.searchQ || '').trim()
			try {
				const result = await fetchPromise('lms/EL_Question_List', {
					GroupId: groupId,
					Type: '',
					Search: search,
					IncludeDeleted: false,
					PageNumber: 1,
					PageSize: 100,
				}, { forceRefresh: true, useStaleCacheOnError: false })
				if (loadSeq !== this.questionsLoadSeq || (this.selectedGroup?.Id || 0) !== groupId) return
				const loadedQuestions = Array.isArray(result?.[0]) ? result[0] : (result || [])
				// Chuẩn hóa dữ liệu đã có ngay sau khi API trả về để toàn bộ câu hỏi môn Tin học hiển thị cùng thang điểm 0.25.
				this.DSQuestion = loadedQuestions.map(question => ({ ...question, Points: this.normalizeQuestionPoints(question?.Points) }))
				if (preserveScroll && savedScrollTop > 0) {
					this.$nextTick(() => {
						const currentWrapper = this.getQuestionTableWrapper()
						if (currentWrapper) currentWrapper.scrollTop = savedScrollTop
					})
				}
			} finally {
				// Request cũ không được phép tắt loading của request mới hơn khi người dùng click nhanh nhiều nhóm.
				if (loadSeq === this.questionsLoadSeq) this.questionsLoading = false
			}
		},
		getYoutubeVideoId(url) {
			const value = String(url || '').trim()
			if (!value) return ''
			try {
				const parsed = new URL(value)
				if (parsed.hostname.includes('youtube.com')) return parsed.searchParams.get('v') || parsed.pathname.split('/').filter(Boolean).pop() || ''
				if (parsed.hostname.includes('youtu.be')) return parsed.pathname.slice(1).split('/')[0] || ''
			} catch (error) {}
			const match = value.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{6,})/i)
			return match ? match[1] : ''
		},
		ensureYoutubeApiLoaded() {
			if (window.YT && window.YT.Player) return Promise.resolve(window.YT)
			if (window.__contentHubYoutubeApiPromise) return window.__contentHubYoutubeApiPromise
			window.__contentHubYoutubeApiPromise = new Promise(resolve => {
				const previousReady = window.onYouTubeIframeAPIReady
				window.onYouTubeIframeAPIReady = () => {
					if (typeof previousReady === 'function') previousReady()
					resolve(window.YT)
				}
				if (!document.querySelector('script[src*="youtube.com/iframe_api"]')) {
					const script = document.createElement('script')
					script.src = 'https://www.youtube.com/iframe_api'
					document.head.appendChild(script)
				}
			})
			return window.__contentHubYoutubeApiPromise
		},
		destroyInteractiveYoutubePlayer() {
			if (this.interactiveVideoTimer) {
				clearInterval(this.interactiveVideoTimer)
				this.interactiveVideoTimer = null
			}
			if (this._interactiveYoutubePlayer) {
				try { this._interactiveYoutubePlayer.destroy() } catch (error) {}
				this._interactiveYoutubePlayer = null
			}
			this.interactiveVideoPlaying = false
		},
		initInteractiveYoutubePlayer() {
			const videoId = this.interactiveYoutubeVideoId
			if (!videoId || this.uploadVideoMode !== 'INTERACTIVE') return
			this.ensureYoutubeApiLoaded().then(() => {
				if (this.interactiveYoutubeVideoId !== videoId || this.uploadVideoMode !== 'INTERACTIVE') return
				this.destroyInteractiveYoutubePlayer()
				this.$nextTick(() => {
					const playerElement = document.getElementById(this.interactiveYoutubePlayerId)
					if (!playerElement || !window.YT?.Player) return
					this._interactiveYoutubePlayer = new window.YT.Player(this.interactiveYoutubePlayerId, {
						height: '100%',
						width: '100%',
						videoId,
						// Tắt UI native của YouTube; shield trong template chặn các overlay còn lại để màn hình chỉ dùng control/timeline tùy chỉnh.
						playerVars: { controls: 0, disablekb: 1, modestbranding: 1, rel: 0, fs: 0, playsinline: 1, cc_load_policy: 0, iv_load_policy: 3 },
						events: { onReady: event => this.onInteractivePlayerReady(event), onStateChange: event => this.onInteractivePlayerStateChange(event) },
					})
				})
			})
		},
		startInteractiveVideoTimer() {
			if (this.interactiveVideoTimer) clearInterval(this.interactiveVideoTimer)
			this.interactiveVideoTimer = setInterval(() => {
				if (this.isDraggingInteractiveTimeline || this.isDraggingInteractiveMarker) return
				const player = this._interactiveYoutubePlayer
				if (this.interactiveYoutubeVideoId && player?.getCurrentTime) {
					try {
						this.interactiveVideoCurrentTime = Math.floor(player.getCurrentTime() || 0)
						this.interactiveVideoDuration = Math.floor(player.getDuration() || 0)
					} catch (error) {}
				} else if (this.$refs.interactiveHtmlPlayer) {
					this.interactiveVideoCurrentTime = this.$refs.interactiveHtmlPlayer.currentTime || 0
					this.interactiveVideoDuration = this.$refs.interactiveHtmlPlayer.duration || 0
				}
			}, 250)
		},
		onInteractivePlayerReady(event) {
			this._interactiveYoutubePlayer = event.target
			this.interactiveVideoDuration = Math.floor(event.target.getDuration?.() || 0)
			this.startInteractiveVideoTimer()
		},
		onInteractivePlayerStateChange(event) {
			this.interactiveVideoPlaying = event.data === window.YT?.PlayerState?.PLAYING
			if (this.interactiveVideoPlaying) this.startInteractiveVideoTimer()
		},
		toggleInteractiveVideoPlay() {
			const player = this._interactiveYoutubePlayer
			if (this.interactiveYoutubeVideoId && player) {
				if (this.interactiveVideoPlaying) player.pauseVideo?.()
				else player.playVideo?.()
			} else if (this.$refs.interactiveHtmlPlayer) {
				if (this.interactiveVideoPlaying) this.$refs.interactiveHtmlPlayer.pause()
				else this.$refs.interactiveHtmlPlayer.play()
			}
		},
		seekInteractiveVideo(seconds) {
			const value = Math.max(0, Math.floor(Number(seconds) || 0))
			this.interactiveVideoCurrentTime = value
			if (this.interactiveYoutubeVideoId) this._interactiveYoutubePlayer?.seekTo?.(value, true)
			else if (this.$refs.interactiveHtmlPlayer) this.$refs.interactiveHtmlPlayer.currentTime = value
		},
		// VSlider phát sự kiện click sau khi cập nhật model; seek ngay lần nữa để player và thumb kết thúc cùng một mốc.
		onInteractiveTimelineSliderCommit() {
			this.seekInteractiveVideo(this.interactiveVideoCurrentTime)
		},
		onInteractiveHtmlTimeUpdate(event) {
			if (!this.isDraggingInteractiveTimeline && !this.isDraggingInteractiveMarker) this.interactiveVideoCurrentTime = event.target.currentTime || 0
		},
		onInteractiveHtmlMetadata(event) {
			this.interactiveVideoDuration = Math.floor(event.target.duration || 0)
		},
		formatTime(seconds) {
			if (seconds === undefined || seconds === null || isNaN(Number(seconds))) return '00:00'
			const total = Math.max(0, Math.floor(Number(seconds)))
			const hours = Math.floor(total / 3600)
			const minutes = Math.floor((total % 3600) / 60)
			const secs = total % 60
			const result = (minutes < 10 ? '0' : '') + minutes + ':' + (secs < 10 ? '0' : '') + secs
			return hours ? (hours < 10 ? '0' : '') + hours + ':' + result : result
		},
		parseInteractiveTime(value) {
			const parts = String(value || '').split(':').map(Number)
			if (parts.some(isNaN)) return 0
			if (parts.length === 3) return parts[0] * 3600 + parts[1] * 60 + parts[2]
			if (parts.length === 2) return parts[0] * 60 + parts[1]
			return parts[0] || 0
		},
		onInteractiveTimelineMouseDown(event) {
			if (event.target?.closest?.('.content-hub-interactive-marker')) return
			const track = this.$refs.interactiveTimelineTrack
			if (!track) return
			this.isDraggingInteractiveTimeline = true
			const updateTime = currentEvent => {
				const rect = track.getBoundingClientRect()
				const clientX = currentEvent.clientX || currentEvent.touches?.[0]?.clientX || 0
				const ratio = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width))
				this.interactiveVideoCurrentTime = Math.floor(ratio * (this.interactiveVideoDuration || 1))
			}
			updateTime(event)
			const move = currentEvent => { if (this.isDraggingInteractiveTimeline) updateTime(currentEvent) }
			const end = () => {
				this.isDraggingInteractiveTimeline = false
				window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', end)
				window.removeEventListener('touchmove', move); window.removeEventListener('touchend', end)
				this.seekInteractiveVideo(this.interactiveVideoCurrentTime)
			}
			window.addEventListener('mousemove', move); window.addEventListener('mouseup', end)
			window.addEventListener('touchmove', move); window.addEventListener('touchend', end)
		},
		onInteractiveMarkerTimeChange(marker, value) {
			const raw = value?.target ? value.target.value : value
			marker.time = Math.max(0, this.parseInteractiveTime(raw))
			marker.timerMarker = marker.time
			this.mergeInteractiveTimerMarkers()
		},
		startDragInteractiveMarker(marker, event) {
			const track = this.$refs.interactiveTimelineTrack
			if (!track) return
			this.isDraggingInteractiveMarker = true
			const update = currentEvent => {
				const rect = track.getBoundingClientRect()
				const clientX = currentEvent.clientX || currentEvent.touches?.[0]?.clientX || 0
				const ratio = Math.max(0, Math.min(1, (clientX - rect.left) / rect.width))
				marker.time = Math.round(ratio * (this.interactiveVideoDuration || 100))
			}
			const move = currentEvent => update(currentEvent)
			const end = () => {
				this.isDraggingInteractiveMarker = false
				window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', end)
				window.removeEventListener('touchmove', move); window.removeEventListener('touchend', end)
				this.mergeInteractiveTimerMarkers()
			}
			update(event)
			window.addEventListener('mousemove', move); window.addEventListener('mouseup', end)
			window.addEventListener('touchmove', move); window.addEventListener('touchend', end)
		},
		newInteractiveMarker(time) {
			return {
				id: 'timer_marker_' + Math.random().toString(36).slice(2, 11),
				time: Math.max(0, Math.floor(Number(time) || 0)),
				timerMarker: Math.max(0, Math.floor(Number(time) || 0)),
				questions: [this.createInteractiveQuestion('Câu hỏi tương tác...')],
			}
		},
		// Câu hỏi trong marker dùng chung schema với Ngân hàng câu hỏi; thêm id để nhiều câu cùng mốc vẫn sửa/xóa độc lập.
		createInteractiveQuestion(prompt = '') {
			return {
				id: 'interactive_question_' + Math.random().toString(36).slice(2, 11),
				type: 'QUIZ_SINGLE_CHOICE',
				content: { prompt },
				config: {
					questionText: prompt,
					points: 1,
					gradingType: 'auto',
					instruction: '',
					submissionNote: '',
					minWords: 0,
					maxLength: 0,
					options: ['', ''],
					correctAnswer: 0,
					correctAnswers: [],
					parts: [{ type: 'text', value: '' }, { type: 'blank', id: 'blank_1', correctAnswer: '', acceptedAnswers: [] }],
					columnA: ['', ''],
					columnB: ['', ''],
					items: [
						{ id: 'ordering_1', text: '' },
						{ id: 'ordering_2', text: '' },
					],
					correctOrder: ['ordering_1', 'ordering_2'],
					scoringMode: 'equal',
				},
			}
		},
		// Chuẩn hóa schema câu hỏi trong video tương tác: ép kiểu options thành mảng chuỗi phẳng, chuẩn hóa correctAnswer thành số nguyên index để v-radio-group binding chính xác
		normalizeInteractiveQuestion(question, fallbackPrompt = '') {
			const defaults = this.createInteractiveQuestion(fallbackPrompt)
			const value = question && typeof question === 'object' ? question : {}
			const content = { ...defaults.content, ...(value.content || {}) }
			const config = { ...defaults.config, ...(value.config || {}) }
			config.questionText = content.prompt || config.questionText || fallbackPrompt
			config.points = this.normalizeQuestionPoints(config.points)
			const questionType = value.type || defaults.type
			if (['SHORT_ANSWER', 'ESSAY'].includes(questionType)) {
				// Chỉ hai dạng chấm tay có đáp án tham khảo; quiz tự động không mang theo key này.
				config.referenceAnswer = this.normalizeQuestionFieldText(config.referenceAnswer || '')
			} else {
				delete config.referenceAnswer
			}
			
			// Đảm bảo options là mảng chuỗi thuần túy để v-text-field binding chính xác
			const rawOptions = Array.isArray(config.options) ? config.options : [...defaults.config.options]
			config.options = rawOptions.map(opt => typeof opt === 'object' ? (opt?.text ?? opt?.value ?? '') : String(opt ?? ''))
			if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'].includes(value.type || defaults.type) && config.options.length < 2) {
				config.options = ['', '']
			}

			// Chuẩn hóa correctAnswer cho QUIZ_SINGLE_CHOICE: luôn là Number (chỉ số index 0, 1, ...)
			let correctIdx = 0
			if (typeof config.correctAnswer === 'number' && config.correctAnswer >= 0) {
				correctIdx = config.correctAnswer
			} else if (typeof config.correctAnswer === 'string' && /^\d+$/.test(config.correctAnswer.trim())) {
				correctIdx = parseInt(config.correctAnswer.trim(), 10)
			} else if (typeof config.correctAnswer === 'string' && config.correctAnswer) {
				const foundIdx = rawOptions.findIndex((opt, idx) => {
					if (typeof opt === 'object') return opt.id === config.correctAnswer || opt.text === config.correctAnswer
					return opt === config.correctAnswer || String(idx) === config.correctAnswer
				})
				if (foundIdx !== -1) correctIdx = foundIdx
			}
			config.correctAnswer = correctIdx

			// Chuẩn hóa correctAnswers cho QUIZ_MULTIPLE_CHOICE: luôn là mảng các Number index
			const rawMulti = Array.isArray(config.correctAnswers) ? config.correctAnswers : []
			config.correctAnswers = rawMulti.map(ans => {
				if (typeof ans === 'number') return ans
				if (typeof ans === 'string' && /^\d+$/.test(ans.trim())) return parseInt(ans.trim(), 10)
				const fIdx = rawOptions.findIndex((opt, idx) => (typeof opt === 'object' ? opt.id === ans : opt === ans || String(idx) === ans))
				return fIdx !== -1 ? fIdx : -1
			}).filter(idx => idx >= 0)

			config.parts = Array.isArray(config.parts) ? config.parts : [...defaults.config.parts]
			config.columnA = Array.isArray(config.columnA) ? config.columnA : [...defaults.config.columnA]
			config.columnB = Array.isArray(config.columnB) ? config.columnB : [...defaults.config.columnB]
			// Interactive question dùng cùng schema với Question Bank để có thể chuyển đổi giữa video và ngân hàng câu hỏi.
			config.items = this.normalizeOrderingItems(config.items, config.correctOrder)
			config.correctOrder = config.items.map(item => item.id)
			if ((value.type || defaults.type) === 'QUIZ_ORDERING') {
				config.scoringMode = 'equal'
				config.gradingType = 'auto'
			}
			return { ...defaults, ...value, id: value.id || defaults.id, content, config }
		},
		// Chuẩn hóa cả dữ liệu mới (marker.questions[]) và dữ liệu cũ (mỗi item có một question) về một mốc duy nhất theo giây.
		normalizeInteractiveTimerMarkers(interactions) {
			let list = interactions
			if (typeof list === 'string') {
				try { list = JSON.parse(list) } catch (error) { list = [] }
			}
			if (!Array.isArray(list)) return []
			const markers = []
			const byTime = new Map()
			const addMarkerQuestions = (rawMarker, rawQuestions, rawTime) => {
				const timeValue = typeof rawTime === 'string' ? this.parseInteractiveTime(rawTime) : Number(rawTime)
				const time = Math.max(0, Math.floor(Number.isFinite(timeValue) ? timeValue : 0))
				const key = String(time)
				let marker = byTime.get(key)
				if (!marker) {
					marker = {
						...(rawMarker && typeof rawMarker === 'object' ? rawMarker : {}),
						id: rawMarker?.id || 'timer_marker_' + Math.random().toString(36).slice(2, 11),
						time,
						timerMarker: time,
						questions: [],
					}
					byTime.set(key, marker)
					markers.push(marker)
				}
				;(Array.isArray(rawQuestions) ? rawQuestions : []).forEach(rawQuestion => {
					const source = rawQuestion?.question && typeof rawQuestion.question === 'object' ? rawQuestion.question : rawQuestion
					if (source && typeof source === 'object') marker.questions.push(this.normalizeInteractiveQuestion(source, source.prompt || 'Câu hỏi tương tác...'))
				})
			}
			list.forEach(item => {
				const rawTime = item?.time ?? item?.timerMarker ?? item?.timeMarker ?? 0
				if (Array.isArray(item?.questions)) addMarkerQuestions(item, item.questions, rawTime)
				else addMarkerQuestions(item, [item?.question || item], rawTime)
			})
			return markers.filter(marker => marker.questions.length).sort((a, b) => a.time - b.time)
		},
		// Khi giáo viên đổi thời gian, các marker trùng giây được gộp lại để một timerMarker luôn chứa nhiều câu hỏi.
		mergeInteractiveTimerMarkers() {
			this.interactiveVideoInteractions = this.normalizeInteractiveTimerMarkers(this.interactiveVideoInteractions)
		},
		// Danh sách mốc chỉ hiển thị đáp án đã thiết lập; cách đọc config tập trung ở đây để mọi dạng câu hỏi dùng chung một preview.
		getInteractiveCorrectAnswer(source) {
			const question = this.normalizeInteractiveQuestion(source?.question || source, source?.prompt || '')
			const config = question.config || {}
			const optionText = option => String(typeof option === 'object' ? (option?.text || option?.value || '') : (option || '')).trim()
			const joinAnswers = values => values.map(optionText).filter(Boolean).join(' · ')
			const getOptionByAnswer = answer => (config.options || []).find((option, index) => String(option?.id ?? index) === String(answer)) || config.options?.[Number(answer)]

			if (question.type === 'QUIZ_SINGLE_CHOICE') return optionText(getOptionByAnswer(config.correctAnswer))
			if (question.type === 'QUIZ_MULTIPLE_CHOICE') return joinAnswers((config.correctAnswers || []).map(getOptionByAnswer))
			if (question.type === 'QUIZ_TRUE_FALSE') return typeof config.correctAnswer === 'boolean' ? (config.correctAnswer ? 'Đúng' : 'Sai') : ''
			if (question.type === 'QUIZ_MULTIPLE_TRUE_FALSE') return (config.options || [])
				.map((statement, index) => {
					const text = optionText(statement)
					const answer = statement?.correctAnswer ? 'Đúng' : statement?.inCorrectAnswer ? 'Sai' : ''
					return text && answer ? `${String.fromCharCode(65 + index)}. ${text}: ${answer}` : ''
				})
				.filter(Boolean).join(' · ')
			if (question.type === 'QUIZ_FILL_IN_BLANK') return joinAnswers((config.parts || []).filter(part => part?.type === 'blank').flatMap(part => part.acceptedAnswers?.length ? part.acceptedAnswers : [part.correctAnswer]))
			if (question.type === 'QUIZ_MATCHING') return (config.columnA || []).map((left, index) => {
				const answer = optionText(config.columnB?.[index])
				return optionText(left) && answer ? `${optionText(left)} → ${answer}` : ''
			}).filter(Boolean).join(' · ')
			if (question.type === 'QUIZ_ORDERING') {
				const items = Array.isArray(config.items) ? config.items : []
				const itemById = new Map(items.map(item => [String(item?.id), item]))
				const order = Array.isArray(config.correctOrder) && config.correctOrder.length ? config.correctOrder : items.map(item => item?.id)
				return order.map(id => optionText(itemById.get(String(id)))).filter(Boolean).join(' → ')
			}
			// Câu trả lời ngắn/tự luận không có đáp án đúng; không trả về nhãn này để UI không hiện "Đáp án đúng: Chấm thủ công".
			return ''
		},
		getInteractiveResponseLimit(question) {
			const config = question?.config || {}
			const limits = []
			const minWords = Number(config.minWords || 0)
			const maxLength = Number(config.maxLength || 0)
			if (minWords > 0) limits.push(`Tối thiểu ${minWords} từ`)
			if (maxLength > 0) limits.push(`Tối đa ${maxLength} ký tự`)
			return limits.join(' · ')
		},
		// Khi đổi loại, tạo tối thiểu các dòng cần nhập để người dùng nhìn thấy đúng dạng câu hỏi ngay lập tức.
			onInteractiveQuestionTypeChange(type) {
			const question = this.interactiveEditing?.question
			if (!question) return
			question.config = this.normalizeInteractiveQuestion(question, question.content?.prompt).config
			question.config.gradingType = this.getQuestionGradingType(type, question.config.gradingType)
			if (['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE'].includes(type) && question.config.options.length < 2) question.config.options = ['', '']
			if (type === 'QUIZ_TRUE_FALSE' && typeof question.config.correctAnswer !== 'boolean') question.config.correctAnswer = true
			if (type === 'QUIZ_MULTIPLE_TRUE_FALSE' && (question.config.options.length < 2 || question.config.options.some(option => !option || typeof option !== 'object'))) question.config.options = [{ text: '', correctAnswer: false, inCorrectAnswer: false }, { text: '', correctAnswer: false, inCorrectAnswer: false }]
			if (type === 'QUIZ_FILL_IN_BLANK' && !question.config.parts.length) question.config.parts = [{ type: 'text', value: '' }, { type: 'blank', id: 'blank_' + Date.now(), correctAnswer: '', acceptedAnswers: [] }]
			if (type === 'QUIZ_MATCHING' && !question.config.columnA.length) { question.config.columnA = ['', '']; question.config.columnB = ['', ''] }
			if (type === 'QUIZ_ORDERING' && (!question.config.items || question.config.items.length < 2)) {
				question.config.items = [{ id: 'ordering_' + Date.now() + '_1', text: '' }, { id: 'ordering_' + Date.now() + '_2', text: '' }]
				question.config.correctOrder = question.config.items.map(item => item.id)
			}
		},
		addInteractiveMarker() {
			const previous = this.interactiveVideoInteractions[this.interactiveVideoInteractions.length - 1]
			const marker = this.newInteractiveMarker(previous ? previous.time + 10 : 10)
			this.interactiveVideoInteractions.push(marker)
		},
		addInteractiveQuestionToMarker(marker) {
			if (!marker) return
			const question = this.createInteractiveQuestion('Câu hỏi tương tác...')
			marker.questions.push(question)
			this.openInteractiveQuestion(marker, question)
		},
		addInteractiveQuestionAtCurrentTime() {
			const time = Math.max(0, Math.floor(Number(this.interactiveVideoCurrentTime) || 0))
			let marker = this.interactiveVideoInteractions.find(item => Number(item.time) === time)
			if (!marker) {
				marker = this.newInteractiveMarker(time)
				this.interactiveVideoInteractions.push(marker)
				this.interactiveVideoInteractions.sort((a, b) => a.time - b.time)
				this.openInteractiveQuestion(marker, marker.questions[0])
				return
			}
			this.addInteractiveQuestionToMarker(marker)
		},
		removeInteractiveMarker(index) {
			this.interactiveVideoInteractions.splice(index, 1)
		},
		removeInteractiveQuestion(marker, questionIndex) {
			if (!marker?.questions) return
			marker.questions.splice(questionIndex, 1)
			if (!marker.questions.length) {
				const markerIndex = this.interactiveVideoInteractions.indexOf(marker)
				if (markerIndex !== -1) this.interactiveVideoInteractions.splice(markerIndex, 1)
			}
		},
		openInteractiveQuestion(marker, question) {
			if (!marker || !question) return
			this.interactiveTarget = { marker, question }
			this.interactiveEditing = { time: marker.time, question: this.normalizeInteractiveQuestion(JSON.parse(JSON.stringify(question)), question.prompt || '') }
			this.interactiveQuestionDialog = true
		},
		// Thêm ô nhập đáp án mới cho câu hỏi trong video tương tác
		addInteractiveOption() {
			if (!this.interactiveEditing?.question?.config) return
			if (!Array.isArray(this.interactiveEditing.question.config.options)) {
				this.interactiveEditing.question.config.options = []
			}
			this.interactiveEditing.question.config.options.push('')
		},
		// Xóa đáp án và tự động điều chỉnh lại chỉ số đáp án đúng (correctAnswer / correctAnswers) để tránh lỗi lệch index hoặc mất lựa chọn
		removeInteractiveOption(index) {
			const config = this.interactiveEditing?.question?.config
			if (!config || !Array.isArray(config.options)) return
			config.options.splice(index, 1)
			if (typeof config.correctAnswer === 'number') {
				if (config.correctAnswer === index) config.correctAnswer = 0
				else if (config.correctAnswer > index) config.correctAnswer -= 1
				if (config.correctAnswer >= config.options.length) config.correctAnswer = Math.max(0, config.options.length - 1)
			}
			if (Array.isArray(config.correctAnswers)) {
				config.correctAnswers = config.correctAnswers
					.filter(v => v !== index)
					.map(v => v > index ? v - 1 : v)
			}
		},
		confirmInteractiveQuestion() {
			if (this.interactiveTarget && this.interactiveEditing) {
				this.interactiveEditing.question.config.questionText = this.interactiveEditing.question.content.prompt || ''
				const marker = this.interactiveTarget.marker
				const questionIndex = marker.questions.findIndex(question => question.id === this.interactiveTarget.question.id)
				const updatedQuestion = JSON.parse(JSON.stringify(this.interactiveEditing.question))
				if (questionIndex === -1) marker.questions.push(updatedQuestion)
				else marker.questions.splice(questionIndex, 1, updatedQuestion)
			}
			this.interactiveQuestionDialog = false
		},
		onInteractiveVideoUrlChange(value) {
			// Không tự động gán tên mặc định chung chung "Video YouTube tương tác" để tránh việc các video tương tác đều bị trùng tên.
			// Người dùng có thể nhập tên bài học ở ô trên, hoặc nếu tải file thì hệ thống sẽ tự lấy tên file.
		},
		uploadInteractiveVideoToYoutube(file) {
			const selected = Array.isArray(file) ? file[0] : file
			if (!selected) return
			// Tự động điền tên file (selected.name) vào ô tên nếu người dùng chưa nhập hoặc tên đang là generic cũ
			if (!this.interactiveVideoName || this.interactiveVideoName === 'Video YouTube tương tác' || this.interactiveVideoName === 'Video tương tác') {
				this.interactiveVideoName = selected.name
			}
			if (!window.UploadManager?.uploadLmsYoutube) return this.notify('UploadManager chưa hỗ trợ YouTube.', 'error')
			this.notify('Đang phát hành video tương tác lên YouTube...', 'info')
			window.UploadManager.uploadLmsYoutube(selected, {
				playlistName: 'Content Hub', title: this.interactiveVideoName || selected.name,
				onComplete: result => {
					if (!this.interactiveVideoName) this.interactiveVideoName = selected.name
					this.interactiveVideoId = result?.id || ''
					this.interactiveVideoUrl = result?.source || (result?.id ? 'https://youtu.be/' + result.id : '')
					this.notify('Đã phát hành video. Hãy thêm các mốc tương tác rồi lưu.')
				},
				onError: error => this.notify(error?.message || 'Phát hành video tương tác thất bại.', 'error'),
			})
		},
		async saveInteractiveVideo() {
			const url = String(this.interactiveVideoUrl || '').trim()
			if (!/^https?:\/\//i.test(url)) return this.notify('Vui lòng nhập hoặc upload một video hợp lệ.', 'warning')
			// Tên video do người dùng đặt hoặc lấy từ tên file upload; cảnh báo nếu chưa nhập tên
			const finalName = String(this.interactiveVideoName || '').trim()
			if (!finalName) return this.notify('Vui lòng nhập tên video / tên tài liệu tương tác.', 'warning')
			// Lưu cùng một cấu trúc nhóm vào cả tên mới và tên cũ để module mới đọc timerMarkers, còn player cũ vẫn đọc interactions.
			const timerMarkers = this.normalizeInteractiveTimerMarkers(this.interactiveVideoInteractions)
			await this.saveContentMetadata({
				title: finalName,
				fileName: finalName,
				contentType: this.getYoutubeVideoId(url) ? 'video/youtube' : 'video/*',
				uploadSource: this.getYoutubeVideoId(url) ? 'youtube' : 'link',
				externalManaged: Boolean(this.interactiveVideoId),
				videoId: this.interactiveVideoId || null,
				url,
				timerMarkers: JSON.parse(JSON.stringify(timerMarkers)),
				interactions: JSON.parse(JSON.stringify(timerMarkers)),
				interactive: true,
			}, finalName, this.interactiveEditingDocument?.NoiDungID || 0)
		},
		resetInteractiveVideoEditor() {
			this.destroyInteractiveYoutubePlayer()
			this.interactiveVideoUrl = ''; this.interactiveVideoName = ''; this.interactiveVideoId = ''
			this.interactiveEditingDocument = null
			this.interactiveVideoInteractions = []; this.interactiveVideoCurrentTime = 0; this.interactiveVideoDuration = 0
			this.interactiveEditing = null; this.interactiveTarget = null; this.interactiveQuestionDialog = false
		},
		openInteractiveVideoEditor(item) {
			const meta = this.getMeta(item)
			// Nạp bản sao để việc thêm/xóa mốc trong dialog chỉ ghi xuống server sau khi người dùng bấm Lưu video tương tác.
			this.resetInteractiveVideoEditor()
			this.pendingUploadType = 'VIDEO'
			this.uploadVideoMode = 'INTERACTIVE'
			this.interactiveEditingDocument = item
			this.interactiveVideoUrl = meta.url || this.getFileUrl(item)
			// Ưu tiên hiển thị tên tài liệu hiện tại để người dùng có thể đổi tên (thay vì bị dính tên 'Video YouTube tương tác')
			this.interactiveVideoName = item.displayName || meta.fileName || meta.title || item.TenNoiDung || ''
			this.interactiveVideoId = meta.videoId || ''
			this.interactiveVideoInteractions = this.normalizeInteractiveTimerMarkers(meta.timerMarkers || meta.interactions || [])
			this.dialogUpload = true
		},
		openAddGroup() {
			if (!this.selectedMon) return this.notify('Vui lòng chọn Khối/Môn trước khi tạo nhóm.', 'warning')
			this.groupForm = { SourceId: 'group_' + Date.now(), Title: '', Description: '', OrdinalNumber: null, MediaJson: null, RawJson: null }
			this.dialogGroup = true
		},
		openUploadDialog() {
			if (!this.canUploadCurrentContext) return this.notify('Vui lòng chọn context trước khi tải tài liệu.', 'warning')
			this.pendingUploadType = ''
			this.uploadVideoMode = 'STANDARD'
			this.uploadVideoName = ''
			this.uploadVideoUrl = ''; this.uploadAudioUrl = ''; this.uploadHtmlContent = ''; this.uploadSlideUrl = ''; this.uploadSlideTab = 'upload'
			this.resetInteractiveVideoEditor()
			this.ispringUploadProgress = { show: false, percent: 0, text: '' }
			this.dialogUpload = true
		},
		openInitiativeFilePicker() {
			if (!this.canUploadCurrentContext) return this.notify('Vui lòng chọn bộ tài nguyên Sáng kiến trước khi tải file.', 'warning')
			// FILE là loại node riêng cho file tải trực tiếp; uploadSelectedFiles chỉ gọi LMS_FileData, không gọi Google Drive.
			this.pendingUploadType = 'FILE'
			this.$nextTick(() => this.$refs.initiativeFileInput?.click())
		},
		openProfileFilePicker() {
			if (!this.canUploadCurrentContext) return this.notify('Hồ sơ cá nhân chưa sẵn sàng. Vui lòng thử lại.', 'warning')
			// File Hồ sơ dùng chung storage LMS với Khối môn, nhưng giữ ParentID folder để người dùng tự tổ chức cây thư mục.
			this.pendingUploadType = 'FILE'
			this.$nextTick(() => this.$refs.profileFileInput?.click())
		},
		uploadInitiativeFiles(event) {
			// Tái sử dụng luồng lưu file LMS dùng chung để giữ metadata storage/fileId phục vụ xóa đúng file sau này.
			return this.uploadSelectedFiles(event)
		},
		uploadProfileFiles(event) {
			return this.uploadSelectedFiles(event)
		},
		// Tên hiển thị phải lấy từ file người dùng chọn; FILE_NAME của API có thể là tên lưu nội bộ đã bị chuẩn hóa.
		getLogicalUploadFileName(file, uploaded = {}) {
			return String(file?.name || uploaded?.FILE_NAME || uploaded?.FileName || 'Tài liệu').trim() || 'Tài liệu'
		},
		confirmUploadType() {
			const type = this.materialTypeOptions.find(item => item.value === this.pendingUploadType)
			if (!type) return this.notify('Vui lòng chọn loại tài liệu.', 'warning')
			this.dialogUpload = false
			this.$nextTick(() => this.$refs.uploadFileInput?.click())
		},
		async ensureUploadLibrary() {
			// Hồ sơ/Sáng kiến có kho riêng theo nghiệp vụ; chỉ nhánh Khối/Môn mới
			// phải resolve lại kho dùng chung theo cặp KhoiID + MonHocID.
			if (this.activeBranch !== 'subject' && this.selectedLibraryId) return this.selectedLibraryId
			if (this.activeBranch === 'initiative') {
				// Người dùng không chọn library ở nhánh Sáng kiến; dùng library đầu tiên làm đích lưu mặc định.
				const library = this.innovationLibraries[0]
				if (library?.HocLieuID) {
					this.selectedLibraryId = library.HocLieuID
					return library.HocLieuID
				}
				return null
			}
			if (!this.selectedMon) return null
			// Cây tài liệu được chia sẻ theo Khối/Môn, còn Node_Save chỉ nhận ghi vào kho do người dùng tạo.
			let library = this.findOwnedSubjectResourceLibrary(this.selectedMon)
			if (!library) {
				const typeInfo = this.resourceTypes.find(item => (item.TaiNguyenLoaiCode || item.Code) === 'TAI_LIEU_THAM_KHAO')
				await fetchPromise('lms/FP_TaiNguyen_Save', { HocLieuID: 0, TenHocLieu: `Tài liệu ${this.selectedMon.TenMonHoc_HienThi || this.selectedMon.MonHocName || ''}`.trim(), TaiNguyenLoaiID: typeInfo?.TaiNguyenLoaiID, KhoiID: this.selectedMon.KhoiID, MonHocID: this.selectedMon.MonHocID, TinhTrang: 'Private' }, { cache: false })
				await this.loadLibraries()
				library = this.findOwnedSubjectResourceLibrary(this.selectedMon)
			}
			if (library?.HocLieuID) { this.selectedLibraryId = library.HocLieuID; return library.HocLieuID }
			return null
		},
		async uploadSelectedFiles(event) {
			const files = Array.from(event.target.files || [])
			event.target.value = ''
			if (!files.length || !this.pendingUploadType) return
			const hocLieuId = await this.ensureUploadLibrary()
			if (!hocLieuId) return this.notify('Không xác định được kho tài liệu của context hiện tại.', 'error')
			// Sáng kiến dùng dbo.FileData (uploadLmsFile) vì endpoint này phát URL đọc công khai cho Office Viewer.
			// Khối môn vẫn dùng LMS_FileData dùng chung; hai kho có cơ chế quyền/xóa khác nhau nên không trộn storage.
			const uploadMethod = this.activeBranch === 'initiative' ? 'uploadLmsFile' : 'uploadLmsSharedFile'
			const storageCode = this.activeBranch === 'initiative' ? 'LMS_DB_FILEDATA' : 'LMS_LHBS_FILEDATA'
			if (!window.UploadManager?.[uploadMethod]) return this.notify('UploadManager chưa hỗ trợ lưu file LMS.', 'error')
			const uploadType = this.pendingUploadType
			files.forEach(file => window.UploadManager[uploadMethod](file, {
				onComplete: async response => {
					try {
						const uploaded = response?.Files?.[0]
						if (!uploaded?.FILE_ID) throw new Error('API upload không trả về FILE_ID.')
						// Ghi rõ storage để Node_Delete xóa đúng kho khi người tạo xóa tài liệu.
						const ownerUserId = this.getCurrentUserId()
						const logicalFileName = this.getLogicalUploadFileName(file, uploaded)
						const metadata = { uploadSource: 'db', storage: storageCode, fileId: uploaded.FILE_ID, fileName: logicalFileName, contentType: uploaded.FILE_CONTENTTYPE || file.type, fileSize: Number(uploaded.FILE_SIZE || file.size || 0), url: uploaded.FILE_URL || `/FileData/${uploaded.FILE_ID}`, origin: 'CONTENT_HUB', resourceType: uploadType, ownerUserId, ownerUserName: this.getCurrentUserName(), visibilityScope: this.activeBranch === 'subject' ? 'CONTEXT' : 'OWNER_ONLY' }
						await fetchPromise('lms/FP_TaiNguyen_Node_Save', { NoiDungID: 0, HocLieuID: hocLieuId, ParentID: this.activeBranch === 'profile' ? this.profileCurrentFolderId : null, TenNoiDung: logicalFileName, LoaiNoiDung: uploadType, NguonTaiNguyenCode: 'CONTENT_HUB', ThuTu: 0, User: ownerUserId, DataJson: JSON.stringify(metadata) }, { cache: false })
						if (this.activeBranch === 'initiative') await this.loadInnovationResources()
						else await this.loadTree()
						await this.loadSourceFiles(); this.notify(`Đã tải “${metadata.fileName}” lên kho.`)
					} catch (error) { this.notify(error.message || 'Không thể lưu tài liệu vào kho.', 'error') }
				},
				onError: error => this.notify(error?.message || `Upload ${file.name} thất bại.`, 'error'),
			}))
		},
		async saveContentMetadata(metadata, fallbackName = 'Tài liệu', existingNodeId = 0) {
			const hocLieuId = await this.ensureUploadLibrary()
			if (!hocLieuId) throw new Error('Không xác định được kho tài liệu của context hiện tại.')
			const displayName = String(metadata.fileName || metadata.title || fallbackName).trim() || fallbackName
			// getFileUrl dùng metadata.url để mở tài liệu; iSpring dùng tên trường riêng nên cần đồng bộ về url khi lưu.
			// Upload từ Khối/Môn phải mang scope CONTEXT để các giáo viên cùng Khối/Môn
			// đọc được tài liệu; các nhánh Hồ sơ/Sáng kiến vẫn giữ scope riêng của chúng.
			// Chỉ gán ownerUserId mặc định khi tạo node mới; khi cập nhật node cũ không được
			// đổi chủ file sang người đang mở editor.
			const ownerUserId = metadata.ownerUserId || (!existingNodeId ? this.getCurrentUserId() : '')
			const normalizedMetadata = {
				...metadata,
				fileName: metadata.fileName || displayName,
				title: metadata.title || displayName,
				origin: 'CONTENT_HUB',
				resourceType: this.pendingUploadType,
				visibilityScope: this.activeBranch === 'subject' ? 'CONTEXT' : (metadata.visibilityScope || 'OWNER_ONLY'),
				...(ownerUserId ? { ownerUserId, ownerUserName: metadata.ownerUserName || this.getCurrentUserName() } : {}),
			}
			if (!normalizedMetadata.url && normalizedMetadata.iSpringURL) normalizedMetadata.url = normalizedMetadata.iSpringURL
			await fetchPromise('lms/FP_TaiNguyen_Node_Save', { NoiDungID: existingNodeId || 0, HocLieuID: hocLieuId, ParentID: null, TenNoiDung: displayName, LoaiNoiDung: this.pendingUploadType, NguonTaiNguyenCode: 'CONTENT_HUB', ThuTu: 0, DataJson: JSON.stringify(normalizedMetadata) }, { cache: false })
			this.dialogUpload = false
			if (this.activeBranch === 'initiative') await this.loadInnovationResources()
			else await this.loadTree()
			await this.loadSourceFiles(); this.notify(`${existingNodeId ? 'Đã cập nhật' : 'Đã lưu'} “${displayName}” vào kho.`)
		},
		async saveVideoLink() {
			const url = this.uploadVideoUrl.trim()
			if (!/youtube\.com|youtu\.be/i.test(url)) return this.notify('Vui lòng nhập đúng link YouTube.', 'warning')
			// Tên video lấy từ ô nhập của người dùng hoặc fallback nếu để trống
			const finalName = String(this.uploadVideoName || '').trim() || 'Video YouTube'
			await this.saveContentMetadata({ title: finalName, fileName: finalName, contentType: 'video/youtube', uploadSource: 'youtube', externalManaged: false, url })
		},
		async saveAudioLink() {
			const url = this.uploadAudioUrl.trim()
			if (!/^https?:\/\//i.test(url)) return this.notify('Vui lòng nhập link audio hợp lệ.', 'warning')
			await this.saveContentMetadata({ title: 'Audio liên kết', fileName: 'Audio liên kết', contentType: 'audio/*', uploadSource: 'link', externalManaged: false, url })
		},
		async saveSlideDocumentLink() {
			const link = String(this.uploadSlideUrl || '').trim()
			if (!link) return

			let parsed
			try { parsed = new URL(link) } catch (error) { return this.notify('Vui lòng nhập link Google Slides hoặc Canva hợp lệ.', 'warning') }
			if (!/^https?:$/.test(parsed.protocol)) return this.notify('Link tài liệu phải bắt đầu bằng http:// hoặc https://.', 'warning')

			const host = parsed.hostname.toLowerCase()
			let metadata = null

			// Canva chỉ lưu link embed và design id; không coi design id là file Google Drive.
			if (host === 'canva.com' || host.endsWith('.canva.com')) {
				const cleanPath = parsed.pathname.replace(/\/+$/, '')
				const designMatch = cleanPath.match(/\/design\/([^/]+)/i)
				if (!designMatch) return this.notify('Link Canva không đúng định dạng thiết kế.', 'warning')
				let embedPath = cleanPath
				if (/\/watch$/i.test(embedPath)) embedPath = embedPath.replace(/\/watch$/i, '/view')
				if (!/(?:\/view|\/watch)$/i.test(embedPath)) embedPath += '/view'

				metadata = {
					title: 'Canva Presentation', fileName: 'Canva Presentation', contentType: 'text/html', fileSize: 0,
					uploadSource: 'canva', externalManaged: false, driveFileId: designMatch[1], url: `${parsed.origin}${embedPath}?embed`, slideType: 'PPT',
				}
			} else if (host === 'docs.google.com' || host === 'drive.google.com' || host.endsWith('.google.com')) {
				const fileMatch = parsed.pathname.match(/\/d\/([^/]+)/i)
				const fileId = fileMatch ? fileMatch[1] : parsed.searchParams.get('id')
				if (!fileId) return this.notify('Link Google Slides / Drive không đúng định dạng.', 'warning')
				const isPresentation = host === 'docs.google.com' && /\/presentation(?:\/|$)/i.test(parsed.pathname)

				metadata = {
					title: isPresentation ? 'Google Slides Presentation' : 'Google Drive File',
					fileName: isPresentation ? 'Google Slides' : 'Google Drive File',
					contentType: isPresentation ? 'application/vnd.google-apps.presentation' : 'application/octet-stream',
					fileSize: 0, uploadSource: 'ggdrive', externalManaged: false, driveFileId: fileId,
					url: isPresentation ? `https://docs.google.com/presentation/d/${fileId}/preview` : `https://drive.google.com/file/d/${fileId}/preview`,
					slideType: 'PPT',
				}
			} else {
				return this.notify('Chỉ hỗ trợ link Google Slides/Drive hoặc Canva.', 'warning')
			}

			try {
				await this.saveContentMetadata(metadata)
				this.uploadSlideUrl = ''
				this.notify(link.toLowerCase().includes('canva.com') ? 'Đã liên kết link Canva thành công!' : 'Đã liên kết link Google Slides thành công!')
			} catch (error) {
				this.notify(error?.message || 'Không thể lưu link tài liệu.', 'error')
			}
		},
		async importHtmlDocument(file) {
			const selected = Array.isArray(file) ? file[0] : file
			if (!selected) return
			try {
				this.uploadHtmlContent = await selected.text()
				// Chọn file là hoàn tất luồng HTML; không bắt người dùng xem/chỉnh mã nguồn trong dialog.
				await this.saveHtmlDocument(selected.name)
			} catch (error) { this.notify('Không thể đọc hoặc lưu file HTML.', 'error') }
		},
		async saveHtmlDocument(fileName = 'Nội dung HTML') {
			if (!this.uploadHtmlContent.trim()) return
			await this.saveContentMetadata({ title: fileName, fileName, contentType: 'text/html', uploadSource: 'html', htmlContent: this.uploadHtmlContent })
		},
		async uploadVideoToYoutube(file) {
			const selected = Array.isArray(file) ? file[0] : file; if (!selected || !window.UploadManager?.uploadLmsYoutube) return this.notify('UploadManager chưa hỗ trợ YouTube.', 'error')
			const title = String(this.uploadVideoName || '').trim() || selected.name
			this.notify(`Đang phát hành ${title} lên YouTube...`, 'info')
			window.UploadManager.uploadLmsYoutube(selected, { playlistName: 'Content Hub', title, onComplete: result => this.saveContentMetadata({ title, fileName: selected.name, contentType: selected.type || 'video/*', fileSize: selected.size, uploadSource: 'youtube', externalManaged: true, videoId: result.id, url: result.source }), onError: error => this.notify(error?.message || 'Phát hành YouTube thất bại.', 'error') })
		},
		async uploadAudioToLms(fileOrEvent) {
			const selected = fileOrEvent?.target?.files?.[0] || (Array.isArray(fileOrEvent) ? fileOrEvent[0] : fileOrEvent)
			if (fileOrEvent?.target) fileOrEvent.target.value = ''
			if (!selected || typeof selected.name !== 'string' || typeof selected.size !== 'number') return this.notify('Tệp audio tải lên không hợp lệ.', 'error')
			const manager = window.UploadManager
			if (!manager?.uploadLmsSharedFile || !manager?.uploadLmsGoogleDrive) return this.notify('UploadManager chưa hỗ trợ đủ hai kho lưu audio.', 'error')
			const upload = (method, options = {}) => new Promise((resolve, reject) => manager[method](selected, { ...options, onComplete: resolve, onError: reject }))
			let lmsFileId = ''
			let driveFileId = ''
			let nodeSaved = false
			try {
				// Audio cần lưu bản LMS trước; bản này được tham chiếu bằng fileId/storage khi xóa tài liệu.
				this.notify(`Đang lưu “${selected.name}” vào LMS...`, 'info')
				const lmsResponse = await upload('uploadLmsSharedFile')
				const lmsFile = lmsResponse?.Files?.[0]
				if (!lmsFile?.FILE_ID) throw new Error('API LMS_FileData không trả về FILE_ID.')
				lmsFileId = lmsFile.FILE_ID

				// Giữ thêm bản Google Drive để audio có URL phát/preview ổn định như luồng soạn học liệu.
				this.notify(`Đang phát hành “${selected.name}” lên Google Drive...`, 'info')
				const driveFile = await upload('uploadLmsGoogleDrive', { folderPath: 'Content Hub/Audio' })
				driveFileId = driveFile?.id || ''
				if (!driveFileId) throw new Error('Google Drive không trả về mã file.')

				const metadata = {
					title: selected.name,
					fileName: selected.name || lmsFile.FILE_NAME,
					contentType: lmsFile.FILE_CONTENTTYPE || selected.type || 'audio/*',
					fileSize: Number(lmsFile.FILE_SIZE || selected.size || 0),
					uploadSource: 'ggdrive',
					externalManaged: true,
					driveFileId,
					url: `https://drive.google.com/file/d/${driveFileId}/preview`,
					// Node_Delete dùng cặp này để xóa bản LMS-LHBS-file sau khi đã xóa Google Drive.
					storage: 'LMS_LHBS_FILEDATA',
					fileId: lmsFileId,
					dbUrl: lmsFile.FILE_URL || `/FileData/${lmsFileId}`,
					mediaType: 'audio',
					origin: 'CONTENT_HUB',
				}
				await this.saveContentMetadata(metadata)
				nodeSaved = true
				this.notify(`Đã lưu “${selected.name}” vào LMS và Google Drive.`)
			} catch (error) {
				// Nếu chưa tạo node thành công, dọn bản LMS tạm để không để lại file mồ côi.
				if (!nodeSaved && lmsFileId && manager.deleteLmsFileData) await manager.deleteLmsFileData(lmsFileId).catch(() => {})
				this.notify(error?.message || `Không thể lưu audio “${selected.name}”.`, 'error')
			}
		},
		async uploadSlideToDrive(file) {
			const selected = Array.isArray(file) ? file[0] : file
			if (!selected || typeof selected.name !== 'string' || typeof selected.size !== 'number') return this.notify('Tệp PPT, DOC hoặc PDF tải lên không hợp lệ.', 'error')
			const manager = window.UploadManager
			if (!manager?.uploadLmsSharedFile || !manager?.uploadLmsGoogleDrive) return this.notify('UploadManager chưa hỗ trợ đủ hai kho LMS và Google Drive.', 'error')
			const upload = (method, options = {}) => new Promise((resolve, reject) => manager[method](selected, { ...options, onComplete: resolve, onError: reject }))
			let lmsFileId = ''
			let driveFileId = ''
			let nodeSaved = false
			try {
				// Lưu bản LMS trước để node luôn có fileId nội bộ phục vụ phân quyền và xóa dữ liệu.
				this.notify(`Đang lưu “${selected.name}” vào LMS...`, 'info')
				const lmsResponse = await upload('uploadLmsSharedFile')
				const lmsFile = lmsResponse?.Files?.[0]
				if (!lmsFile?.FILE_ID) throw new Error('API LMS_FileData không trả về FILE_ID.')
				lmsFileId = lmsFile.FILE_ID

				// Lưu thêm bản Google Drive để giữ khả năng mở/preview tài liệu theo luồng cũ.
				this.notify(`Đang phát hành “${selected.name}” lên Google Drive...`, 'info')
				const driveFile = await upload('uploadLmsGoogleDrive', { folderPath: 'Content Hub/Slides' })
				driveFileId = driveFile?.id || ''
				if (!driveFileId) throw new Error('Google Drive không trả về mã file.')

				await this.saveContentMetadata({
					title: selected.name,
					fileName: selected.name || lmsFile.FILE_NAME,
					contentType: lmsFile.FILE_CONTENTTYPE || selected.type || 'application/octet-stream',
					fileSize: Number(lmsFile.FILE_SIZE || selected.size || 0),
					uploadSource: 'ggdrive',
					externalManaged: true,
					driveFileId,
					url: `https://drive.google.com/file/d/${driveFileId}/preview`,
					// Node_Delete dùng cặp storage/fileId để dọn đúng bản LMS sau khi xử lý bản Drive.
					storage: 'LMS_LHBS_FILEDATA',
					fileId: lmsFileId,
					dbUrl: lmsFile.FILE_URL || `/FileData/${lmsFileId}`,
					mediaType: 'slide',
					origin: 'CONTENT_HUB',
				})
				nodeSaved = true
				this.notify(`Đã lưu “${selected.name}” vào LMS và Google Drive.`)
			} catch (error) {
				// Nếu chưa ghi node thành công, dọn bản LMS tạm để tránh tạo file mồ côi.
				if (!nodeSaved && lmsFileId && manager.deleteLmsFileData) await manager.deleteLmsFileData(lmsFileId).catch(() => {})
				this.notify(error?.message || `Không thể lưu tài liệu “${selected.name}”.`, 'error')
			}
		},
		async uploadImageFile(file) {
			const selected = file?.target?.files?.[0] || (Array.isArray(file) ? file[0] : file)
			if (!selected || typeof selected.name !== 'string' || typeof selected.size !== 'number') return this.notify('Tệp hình ảnh tải lên không hợp lệ.', 'error')
			return this.uploadImageToBothStorages(selected)
		},
		async uploadImageToBothStorages(selected) {
			const manager = window.UploadManager
			if (!manager?.uploadLmsSharedFile || !manager?.uploadLmsGoogleDrive) return this.notify('UploadManager chưa hỗ trợ đủ hai kho lưu hình ảnh.', 'error')
			const upload = (method, options = {}) => new Promise((resolve, reject) => manager[method](selected, { ...options, onComplete: resolve, onError: reject }))
			let lmsFileId = ''
			let driveFileId = ''
			let nodeSaved = false
			try {
				// Ảnh được lưu cả hai kho: LMS làm bản dữ liệu nội bộ, Google Drive làm bản preview/quản lý ngoài.
				this.notify(`Đang lưu “${selected.name}” vào LMS...`, 'info')
				const lmsResponse = await upload('uploadLmsSharedFile')
				const lmsFile = lmsResponse?.Files?.[0]
				if (!lmsFile?.FILE_ID) throw new Error('API LMS_FileData không trả về FILE_ID.')
				lmsFileId = lmsFile.FILE_ID

				this.notify(`Đang phát hành “${selected.name}” lên Google Drive...`, 'info')
				const driveFile = await upload('uploadLmsGoogleDrive', { folderPath: 'Content Hub/Images' })
				driveFileId = driveFile?.id || ''
				if (!driveFileId) throw new Error('Google Drive không trả về mã file.')

				await this.saveContentMetadata({
					title: selected.name,
					fileName: selected.name || lmsFile.FILE_NAME,
					contentType: lmsFile.FILE_CONTENTTYPE || selected.type || 'image/*',
					fileSize: Number(lmsFile.FILE_SIZE || selected.size || 0),
					uploadSource: 'ggdrive',
					externalManaged: true,
					driveFileId,
					url: `https://drive.google.com/file/d/${driveFileId}/preview`,
					// Node_Delete dùng cặp storage/fileId để dọn đúng bản LMS khi node không còn tham chiếu.
					storage: 'LMS_LHBS_FILEDATA',
					fileId: lmsFileId,
					dbUrl: lmsFile.FILE_URL || `/FileData/${lmsFileId}`,
					mediaType: 'image',
					origin: 'CONTENT_HUB',
				})
				nodeSaved = true
				this.notify(`Đã lưu “${selected.name}” vào LMS và Google Drive.`)
			} catch (error) {
				// Nếu ghi node thất bại, dọn bản LMS tạm để không tạo file mồ côi; bản Drive sẽ được xử lý theo quyền token hiện có.
				if (!nodeSaved && lmsFileId && manager.deleteLmsFileData) await manager.deleteLmsFileData(lmsFileId).catch(() => {})
				this.notify(error?.message || `Không thể lưu hình ảnh “${selected.name}”.`, 'error')
			}
		},
		async uploadBinaryFile(file, mediaType) {
			const selected = file?.target?.files?.[0] || (Array.isArray(file) ? file[0] : file)
			if (!selected || typeof selected.name !== 'string' || typeof selected.size !== 'number') return this.notify('Tệp tải lên không hợp lệ.', 'error')
			await this.uploadSelectedFiles({ target: { files: [selected], value: '' } })
		},
		async uploadDriveFile(file, mediaType) {
			const selected = Array.isArray(file) ? file[0] : file; if (!selected || !window.UploadManager?.uploadLmsGoogleDrive) return this.notify('UploadManager chưa hỗ trợ Google Drive.', 'error')
			this.notify(`Đang phát hành ${selected.name} lên Google Drive...`, 'info')
			window.UploadManager.uploadLmsGoogleDrive(selected, { folderPath: 'Content Hub', onComplete: result => this.saveContentMetadata({ title: selected.name, fileName: selected.name, contentType: selected.type, fileSize: selected.size, uploadSource: 'ggdrive', externalManaged: true, driveFileId: result.id, mediaType, url: `https://drive.google.com/file/d/${result.id}/preview` }), onError: error => this.notify(error?.message || 'Phát hành Google Drive thất bại.', 'error') })
		},
		async uploadISpringFolder(event) {
			const files = Array.from(event?.target?.files || event?.dataTransfer?.files || [])
			if (!files.length) return
			if (event?.target) event.target.value = ''
			if (!files.some(file => file.name.toLowerCase() === 'index.html')) return this.notify('Không tìm thấy file index.html trong folder iSpring.', 'error')
			const config = await fetchPromise('lms/FP_Github_Config_Get')
			if (!config?.token || !config.owner || !config.repo) return this.notify('Chưa cấu hình GitHub để phát hành iSpring.', 'error')
			const guid = globalThis.crypto?.randomUUID ? globalThis.crypto.randomUUID() : `${Date.now()}-${Math.random().toString(36).slice(2)}`
			const firstRelativePath = files[0].webkitRelativePath || files[0].name
			const root = firstRelativePath.includes('/') ? firstRelativePath.split('/')[0] : ''
			this.ispringUploadProgress = { show: true, percent: 0, text: 'Đang chuẩn bị upload...' }
			try {
				for (let index = 0; index < files.length; index += 1) {
					const file = files[index]
					const content = await new Promise((resolve, reject) => { const reader = new FileReader(); reader.onload = () => resolve(String(reader.result).split(',')[1] || ''); reader.onerror = reject; reader.readAsDataURL(file) })
					const relative = file.webkitRelativePath || file.name
					const path = `content/${guid}/${relative}`
					const response = await fetch(`https://api.github.com/repos/${config.owner}/${config.repo}/contents/${path.split('/').map(encodeURIComponent).join('/')}`, { method: 'PUT', headers: { Authorization: `token ${config.token}`, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' }, body: JSON.stringify({ message: `Upload iSpring ${file.name}`, content, branch: config.branch || 'main' }) })
					if (!response.ok) throw new Error(`GitHub upload lỗi ${response.status}`)
					const completed = index + 1
					this.ispringUploadProgress = { show: true, percent: Math.round((completed / files.length) * 100), text: `Đang upload ${completed}/${files.length} tệp...` }
				}
				const indexFile = files.find(file => file.name.toLowerCase() === 'index.html')
				const indexParts = (indexFile.webkitRelativePath || indexFile.name).split('/')
				if (indexParts.length > 1) indexParts.shift()
				const indexPath = indexParts.join('/')
				const encodedRoot = root ? `${encodeURIComponent(root)}/` : ''
				const iSpringURL = `https://thientamlhu.github.io/lhbs.lms/content/${guid}/${encodedRoot}${indexPath}`
				this.ispringUploadProgress = { show: true, percent: 100, text: 'Upload iSpring thành công, đang lưu vào kho...' }
				await this.saveContentMetadata({ title: root || 'iSpring Content', fileName: root || 'iSpring Content', contentType: 'application/x-ispring', uploadSource: 'github-ispring', externalManaged: true, iSpringGUID: guid, iSpringURL, folderName: root, encodedFolderName: root ? encodeURIComponent(root) : '', uploadDate: new Date().toISOString(), totalFiles: files.length })
			} catch (error) {
				this.ispringUploadProgress = { show: false, percent: 0, text: '' }
				this.notify(error.message || 'Upload iSpring thất bại.', 'error')
			}
		},
		openEditGroup(group) {
			this.groupForm = { ...group }
			this.dialogGroup = true
		},
		async saveGroup() {
			if (!this.groupForm.Title?.trim()) return this.notify('Vui lòng nhập tên nhóm.', 'warning')
			this.savingGroup = true
			try {
				const isEdit = Boolean(this.groupForm.Id)
				const sourceId = this.groupForm.SourceId || ('group_' + Date.now())
				const payload = {
					...(isEdit ? { Id: this.groupForm.Id } : {}), SourceId: sourceId,
					KhoiID: this.selectedMon?.KhoiID, MonHocID: this.selectedMon?.MonHocID, Title: this.groupForm.Title.trim(),
					Description: this.groupForm.Description || null, OrdinalNumber: this.groupForm.OrdinalNumber ?? null,
					MediaJson: this.groupForm.MediaJson || null, RawJson: this.groupForm.RawJson || null, User: this.vueData.user?.UserID,
				}
				const result = await fetchPromise('lms/EL_QuestionGroup_' + (isEdit ? 'Update' : 'Create'), payload, { cache: false })
				if (!this.isApiSuccess(result)) return this.notify('Không thể lưu nhóm câu hỏi.', 'error')
				// Lấy Id của nhóm mới tạo từ response hoặc từ payload sửa
				const flatResult = Array.isArray(result?.[0]) ? result[0][0] : (Array.isArray(result) ? result[0] : result)
				const createdId = flatResult?.Id || flatResult?.id || (isEdit ? this.groupForm.Id : null)
				this.dialogGroup = false
				// BẮT BUỘC: Tự động chọn nhóm câu hỏi vừa tạo/cập nhật để người dùng thao tác tiếp ngay mà không phải click chọn thủ công.
				await this.loadGroups(createdId, sourceId)
				this.notify(isEdit ? 'Đã cập nhật nhóm câu hỏi.' : 'Đã tạo nhóm câu hỏi.')
			} finally { this.savingGroup = false }
		},
		async deleteGroup(group) {
			const ok = await this.confirmRef?.value?.show?.({ title: 'Xóa nhóm "' + (group.Title || '') + '"?' })
			if (!ok) return
			const result = await fetchPromise('lms/EL_QuestionGroup_Delete', { Id: group.Id, User: this.vueData.user?.UserID }, { cache: false })
			if (!this.isApiSuccess(result)) return this.notify('Không thể xóa nhóm câu hỏi.', 'error')
			if (this.selectedGroup?.Id === group.Id) { this.selectedGroup = null; this.DSQuestion = [] }
			await this.loadGroups()
			this.notify('Đã xóa nhóm câu hỏi.')
		},
		// Dữ liệu câu hỏi có thể đến từ import/AI dưới dạng string, object hoặc HTML; chuẩn hóa một chỗ để mọi field trong dialog nhận đúng text.
		normalizeQuestionFieldText(value) {
			if (value === null || value === undefined) return ''
			if (typeof value === 'object') {
				const nestedValue = value.text ?? value.content ?? value.html ?? value.label ?? value.value ?? ''
				return nestedValue && typeof nestedValue === 'object' ? this.normalizeQuestionFieldText(nestedValue) : String(nestedValue)
			}
			return String(value)
		},
		// Ô nhập đáp án thường không hiển thị rich-text; thay ảnh data-uri bằng nhãn ngắn và loại tag cho các môn không phải Tin học.
		toPlainQuestionText(value) {
			return this.normalizeQuestionFieldText(value)
				.replace(/<img\b[^>]*\bsrc\s*=\s*["']data:image\/[^"']+["'][^>]*>/gi, '[Hình ảnh]')
				.replace(/<img\b[^>]*>/gi, '[Hình ảnh]')
				.replace(/<br\s*\/?>/gi, '\n')
				.replace(/<\/(?:p|div|li|h[1-6])\s*>/gi, '\n')
				.replace(/<[^>]+>/g, ' ')
				.replace(/&nbsp;/gi, ' ')
				.replace(/&amp;/gi, '&')
				.replace(/&lt;/gi, '<')
				.replace(/&gt;/gi, '>')
				.replace(/[ \t]{2,}/g, ' ')
				.replace(/\n{3,}/g, '\n\n')
				.trim()
		},
		// Input của môn Tin học phải giữ nguyên mã nguồn; các môn khác vẫn dùng bản text rút gọn cho ô nhập thường.
		getQuestionEditorText(value) {
			const normalized = this.normalizeQuestionFieldText(value)
			return this.isComputerSubjectContext ? normalized : this.toPlainQuestionText(normalized)
		},
		// CKEditor sẽ coi <html>/<head>/<title> trong mã nguồn là cấu trúc tài liệu và tự loại chúng; encode riêng lúc nạp editor để giữ nguyên mã Tin học.
		escapeQuestionSourceForEditor(value) {
			return String(value ?? '').replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;')
		},
		// Chỉ decode lại dữ liệu môn Tin học khi lưu; các môn khác vẫn lưu rich-text HTML như hiện tại.
		decodeQuestionSourceFromEditor(value) {
			return String(value ?? '')
				.replace(/&lt;/gi, '<')
				.replace(/&gt;/gi, '>')
				.replace(/&quot;/gi, '"')
				.replace(/&#39;|&apos;/gi, "'")
				.replace(/&amp;/gi, '&')
		},
		getQuestionTextForSave() {
			// Nội dung câu hỏi bind trực tiếp vào uc-rich-text-editor; không dùng bản text rút gọn làm fallback nếu đã có nội dung gốc.
			const rawEditorText = this.normalizeQuestionFieldText(this.questionForm.QuestionText).trim()
			const editorText = this.isComputerSubjectContext ? this.stripQuestionEditorWrappers(rawEditorText) : rawEditorText
			const richText = this.isComputerSubjectContext ? this.decodeQuestionSourceFromEditor(editorText).trim() : editorText
			if (richText) return richText
			return this.normalizeQuestionFieldText(this.questionForm._plainQuestionText).trim()
		},
		getQuestionSkills(item) {
			// Không hiển thị hoặc mang tiếp SkillsJson cũ trong ngữ cảnh Tiểu học sau khi taxonomy đã bỏ.
			if (this.isPrimarySchoolContext) return []
			const skills = this.parseJson(item?.SkillsJson, [])
			if (!Array.isArray(skills)) return []
			return skills.map(skill => {
				if (skill === null || skill === undefined) return null
				if (typeof skill !== 'object') return { KyNang_MonHoc_ChiTietID: skill, TenKyNang: String(skill), name: String(skill), id: skill }
				const id = skill.KyNang_MonHoc_ChiTietID ?? skill.SkillCode ?? skill.MucDoCode ?? skill.id ?? skill.ID
				const name = skill.TenKyNang ?? skill.name ?? skill.MucDo ?? skill.levelName
				return { ...skill, KyNang_MonHoc_ChiTietID: skill.KyNang_MonHoc_ChiTietID ?? id, TenKyNang: name || skill.TenKyNang || '', name: skill.name || name || '', id: skill.id ?? id }
			}).filter(skill => skill && (skill.KyNang_MonHoc_ChiTietID || skill.SkillCode || skill.MucDoCode || skill.id || skill.TenKyNang))
		},
		getQuestionLevel(item) {
			const config = this.parseJson(item?.ConfigJson, {})
			const candidates = []
			const collect = value => {
				if (value === null || value === undefined || value === '') return
				if (Array.isArray(value)) return value.forEach(collect)
				if (typeof value === 'object') {
					collect(value.KyNang_MonHoc_ChiTietID ?? value.SkillCode ?? value.MucDoCode ?? value.id ?? value.ID)
					collect(value.TenKyNang ?? value.name ?? value.MucDo ?? value.levelName)
					return
				}
				candidates.push(String(value).trim())
			}
			collect(config.questionLevel || config.QuestionLevel || config.MucDo || config.MucDoCode)
			this.getQuestionSkills(item).forEach(skill => {
				collect(skill.KyNang_MonHoc_ChiTietID)
				collect(skill.SkillCode)
				collect(skill.MucDoCode)
				collect(skill.TenKyNang)
				collect(skill.NhomKyNang)
			})
			return this.DSSkill.find(level => candidates.some(candidate => [
				level.KyNang_MonHoc_ChiTietID, level.SkillCode, level.MucDoCode, level.TenKyNang
			].some(value => String(value || '') === candidate || this.normalizeSkillText(value) === this.normalizeSkillText(candidate)))) || null
		},
		normalizeOrderingItems(rawItems, rawOrder) {
			const items = (Array.isArray(rawItems) ? rawItems : []).map((item, index) => ({
				id: String(item?.id ?? item?.value ?? ('ordering_' + (index + 1))),
				text: this.getQuestionEditorText(item?.text ?? item?.label ?? item?.content ?? item?.value ?? item ?? ''),
			}))
			const itemById = new Map(items.map(item => [String(item.id), item]))
			const orderValues = Array.isArray(rawOrder) && rawOrder.length ? rawOrder : items.map(item => item.id)
			const orderedIds = orderValues.map(value => {
				const direct = items.find(item => String(item.id) === String(value))
				if (direct) return direct.id
				const index = Number(value)
				return Number.isInteger(index) && items[index] ? items[index].id : null
			}).filter(Boolean)
			const missingIds = items.map(item => item.id).filter(id => !orderedIds.includes(id))
			return [...orderedIds, ...missingIds].map(id => itemById.get(id)).filter(Boolean)
		},
		createQuestionForm(item) {
			const config = this.parseJson(item?.ConfigJson, {})
			const type = item?.Type || 'QUIZ_SINGLE_CHOICE'
			// Dữ liệu cũ có thể chưa có GradingType; suy luận theo taxonomy giống Soạn bài tập để khi sửa không bị rơi về chấm tự động sai.
			const gradingType = this.getQuestionGradingType(type, item?.GradingType || config.gradingType)
			const rawQuestionText = this.normalizeQuestionFieldText(item?.QuestionText || config.questionText || config.prompt || '')
			const rawOptions = Array.isArray(config.options) && config.options.length ? config.options : []
			const options = rawOptions.length ? rawOptions.map(option => this.normalizeQuestionFieldText(option)) : ['', '']
			const plainOptions = options.map(option => this.getQuestionEditorText(option))
			const optionMatchesAnswer = (option, index, answer) => String(answer) === String(option?.id ?? '') || String(answer) === String(index) || String(answer) === String.fromCharCode(97 + index)
			const correctIndex = Math.max(0, rawOptions.findIndex((option, index) => optionMatchesAnswer(option, index, config.correctAnswer)))
			const correctIndexes = Array.isArray(config.correctAnswers) ? config.correctAnswers.map(answer => rawOptions.findIndex((option, index) => optionMatchesAnswer(option, index, answer))).filter(index => index >= 0) : []
			
			// Xử lý options / mệnh đề cho Đúng / Sai
			let tfOptions = []
			if (Array.isArray(config.options) && config.options.length) {
				tfOptions = config.options.map(opt => ({
					text: this.getQuestionEditorText(opt.text ?? opt),
					correctAnswer: opt.correctAnswer === true || opt.correctAnswer === 'true' || opt.correctAnswer === 1,
					inCorrectAnswer: opt.inCorrectAnswer === true || opt.inCorrectAnswer === 'true' || opt.inCorrectAnswer === 1,
				}))
			}
			// Dữ liệu cũ có thể không lưu scoringMode; đủ 4 mệnh đề thì luôn suy ra chấm theo từng ý.
			if (type === 'QUIZ_MULTIPLE_TRUE_FALSE' && !tfOptions.length) {
				tfOptions = [
					{ text: '', correctAnswer: false, inCorrectAnswer: false },
					{ text: '', correctAnswer: false, inCorrectAnswer: false },
				]
			}
			const tfScoringMode = tfOptions.length === 4 ? 'partial' : (config.scoringMode === 'partial' ? 'partial' : 'equal')
			let tfAnswer = true
			if (config.correctAnswer === false || config.correctAnswer === 'false' || config.correctAnswer === 0) tfAnswer = false

			// Ô trống giữ mảng acceptedAnswers để người dùng thêm/xóa từng đáp án; dữ liệu cũ dạng "a / b" vẫn được chuyển đổi.
			let blankParts = []
			if (Array.isArray(config.parts) && config.parts.length) {
				blankParts = config.parts.map((p, index) => {
					if ((p.type || 'text') !== 'blank') return { type: 'text', value: p.value || '' }
					const acceptedAnswers = Array.isArray(p.acceptedAnswers)
						? p.acceptedAnswers.map(answer => String(answer).trim()).filter(Boolean)
						: String(p.correctAnswer || '').split('/').map(answer => answer.trim()).filter(Boolean)
					return {
						type: 'blank',
						id: p.id || ('blank_' + index),
						correctAnswer: acceptedAnswers[0] || '',
						acceptedAnswers,
					}
				})
			} else {
				blankParts = [
					{ type: 'text', value: '' },
					{ type: 'blank', id: 'blank_1', correctAnswer: '', acceptedAnswers: [] },
				]
			}

			// Xử lý các cặp ghép nối cho Nối đáp án
			let matchingPairs = []
			if (Array.isArray(config.columnA) && config.columnA.length) {
				const colB = Array.isArray(config.columnB) ? config.columnB : []
				matchingPairs = config.columnA.map((colAItem, idx) => ({
					left: this.getQuestionEditorText(colAItem),
					right: this.getQuestionEditorText(colB[idx]),
				}))
			} else {
				matchingPairs = [{ left: '', right: '' }, { left: '', right: '' }]
			}
			// Form luôn hiển thị theo thứ tự đúng; khi lưu sẽ ghi lại cả items và correctOrder để không mất ID mapping.
			const rawOrderingItems = Array.isArray(config.items) ? config.items : (Array.isArray(config.options) ? config.options : [])
			const orderingItems = this.normalizeOrderingItems(rawOrderingItems, config.correctOrder)

			// Cờ Nâng cao (isAdvanced) phục vụ việc soạn thảo LaTeX/công thức cho phần Đáp án (options).
			// Ưu tiên cờ do người dùng đã lưu (config.isAdvanced hoặc item.IsAdvanced).
			// Không quét HTML của QuestionText vì nội dung câu hỏi từ CKEditor luôn chứa thẻ <p>, gây false-positive tự bật Nâng cao.
			// Chỉ fallback auto-detect qua options khi câu hỏi chưa có cờ lưu trước đó.
			const mathRegex = /(\$|\\\(|\\\[|\\begin\{|<math|data:image\/)/i
			const explicitAdvanced = config.isAdvanced !== undefined
				? Boolean(config.isAdvanced)
				: (item?.IsAdvanced !== undefined && item?.IsAdvanced !== null ? Boolean(item.IsAdvanced) : null)
			const isAdvanced = explicitAdvanced !== null ? explicitAdvanced : options.some(opt => mathRegex.test(opt))

			return {
				...(item || {}),
				Type: type,
				QuestionText: this.isComputerSubjectContext ? this.escapeQuestionSourceForEditor(rawQuestionText) : rawQuestionText,
				GradingType: gradingType,
				_plainQuestionText: this.getQuestionEditorText(rawQuestionText),
				_originalQuestionText: rawQuestionText,
				_originalPlainQuestionText: this.getQuestionEditorText(rawQuestionText),
				Points: this.normalizeQuestionPoints(item?.Points),
				ConfigJson: typeof item?.ConfigJson === 'string' ? item.ConfigJson : '',
				// Tách field khỏi JSON thô để giáo viên chỉnh sửa trực quan; buildQuestionConfig sẽ ghi lại đúng key referenceAnswer.
				_referenceAnswer: ['SHORT_ANSWER', 'ESSAY'].includes(type) ? this.normalizeQuestionFieldText(config.referenceAnswer || '') : '',
				_options: options,
				_plainOptions: plainOptions,
				_originalOptions: [...options],
				_originalPlainOptions: [...plainOptions],
				_correctIndex: correctIndex,
				_correctIndexes: correctIndexes,
				_tfOptions: tfOptions,
				_tfScoringMode: tfScoringMode,
				_tfAnswer: tfAnswer,
				_blankParts: blankParts,
				_matchingPairs: matchingPairs,
				_orderingItems: orderingItems,
				_isAdvanced: isAdvanced,
				_skillIds: this.getQuestionSkills(item).map(skill => skill.KyNang_MonHoc_ChiTietID),
				_media: this.normalizeQuestionMedia(config.media)
			}
		},
		onQuestionTypeChange(newType) {
			if (!this.questionForm) return
			// Khi đổi sang nhóm câu hỏi chấm tay, khóa giá trị thủ công; khi đổi về QUIZ thì phục hồi mặc định tự động nếu giá trị chưa hợp lệ.
			this.questionForm.GradingType = this.getQuestionGradingType(newType, this.questionForm.GradingType)
			if (['SHORT_ANSWER', 'ESSAY'].includes(newType) && this.questionForm._referenceAnswer === undefined) {
				// Khởi tạo key ngay khi chuyển loại để câu hỏi mới luôn có schema thống nhất với Soạn bài tập.
				this.questionForm._referenceAnswer = ''
			}
			if ((newType === 'QUIZ_TRUE_FALSE' || newType === 'QUIZ_MULTIPLE_TRUE_FALSE') && (!this.questionForm._tfOptions || !this.questionForm._tfOptions.length)) {
				this.questionForm._tfOptions = newType === 'QUIZ_MULTIPLE_TRUE_FALSE'
					? [{ text: '', correctAnswer: false, inCorrectAnswer: false }, { text: '', correctAnswer: false, inCorrectAnswer: false }]
					: [{ text: '', correctAnswer: true, inCorrectAnswer: false }, { text: '', correctAnswer: false, inCorrectAnswer: true }]
			}
			if (newType === 'QUIZ_MULTIPLE_TRUE_FALSE') this.questionForm._tfScoringMode = this.questionForm._tfOptions.length === 4 ? 'partial' : 'equal'
			if (newType === 'QUIZ_MATCHING' && (!this.questionForm._matchingPairs || !this.questionForm._matchingPairs.length)) {
				this.questionForm._matchingPairs = [{ left: '', right: '' }, { left: '', right: '' }]
			}
			if (newType === 'QUIZ_FILL_IN_BLANK' && (!this.questionForm._blankParts || !this.questionForm._blankParts.length)) {
				this.questionForm._blankParts = [{ type: 'text', value: '' }, { type: 'blank', id: 'blank_1', correctAnswer: '', acceptedAnswers: [] }]
				this.blankInputs = {}
			}
			if (newType === 'QUIZ_ORDERING' && (!this.questionForm._orderingItems || !this.questionForm._orderingItems.length)) {
				this.questionForm._orderingItems = [
					{ id: 'ordering_' + Date.now() + '_1', text: '' },
					{ id: 'ordering_' + Date.now() + '_2', text: '' },
				]
			}
		},
		isQuestionAutoGradable(type) {
			return String(type || '').startsWith('QUIZ_')
		},
		getQuestionGradingType(type, value) {
			if (!this.isQuestionAutoGradable(type)) return 'manual'
			// Ordering có đáp án chuẩn theo từng vị trí nên luôn dùng luồng quiz tự chấm.
			if (type === 'QUIZ_ORDERING') return 'auto'
			return String(value || 'auto').toLowerCase() === 'manual' ? 'manual' : 'auto'
		},
		onMultipleTrueFalseScoringModeChange(value) {
			this.questionForm._tfScoringMode = value
			if (value !== 'partial') return
			// Chấm theo từng ý luôn dùng đúng 4 mệnh đề A-D, giống Soạn bài tập.
			while (this.questionForm._tfOptions.length < 4) this.questionForm._tfOptions.push({ text: '', correctAnswer: false, inCorrectAnswer: false })
			if (this.questionForm._tfOptions.length > 4) this.questionForm._tfOptions = this.questionForm._tfOptions.slice(0, 4)
		},
		addMultipleTrueFalseStatement() {
			this.questionForm._tfOptions.push({ text: '', correctAnswer: false, inCorrectAnswer: false })
			// Đủ 4 ý thì tự chuyển sang chấm theo từng ý; người dùng không phải nhớ bật thêm tùy chọn.
			if (this.questionForm._tfOptions.length === 4) this.questionForm._tfScoringMode = 'partial'
		},
		removeMultipleTrueFalseStatement(index) {
			this.questionForm._tfOptions.splice(index, 1)
			if (this.questionForm._tfOptions.length !== 4) this.questionForm._tfScoringMode = 'equal'
		},
		// Dùng cùng cách thêm/xóa parts như Soạn bài tập để thứ tự văn bản và ô trống được giữ nguyên khi lưu.
		addQuestionBlankPart(type) {
			if (!this.questionForm?._blankParts) this.questionForm._blankParts = []
			this.questionForm._blankParts.push(type === 'blank'
				? { type: 'blank', id: 'blank_' + Date.now(), correctAnswer: '', acceptedAnswers: [] }
				: { type: 'text', value: '' })
		},
		// Mỗi lần nhấn Enter thêm một đáp án độc lập; không gộp bằng dấu "/" để không làm mất đáp án có ký tự đặc biệt.
		addBlankAnswer(part, index) {
			const value = String(this.blankInputs[index] || '').trim()
			if (!value) return
			if (!Array.isArray(part.acceptedAnswers)) part.acceptedAnswers = []
			if (!part.acceptedAnswers.some(answer => String(answer).trim() === value)) part.acceptedAnswers.push(value)
			part.correctAnswer = part.acceptedAnswers[0] || ''
			this.blankInputs[index] = ''
		},
		removeQuestionBlankPart(index) {
			if (!this.questionForm?._blankParts) return
			this.questionForm._blankParts.splice(index, 1)
			delete this.blankInputs[index]
		},
		moveQuestionOrderingItem(index, direction) {
			const items = this.questionForm?._orderingItems || []
			const targetIndex = index + direction
			if (targetIndex < 0 || targetIndex >= items.length) return
			const moved = items.splice(index, 1)[0]
			items.splice(targetIndex, 0, moved)
		},
		addQuestionOrderingItem() {
			if (!this.questionForm) return
			if (!Array.isArray(this.questionForm._orderingItems)) this.questionForm._orderingItems = []
			this.questionForm._orderingItems.push({ id: 'ordering_' + Date.now() + '_' + this.questionForm._orderingItems.length, text: '' })
		},
		removeQuestionOrderingItem(index) {
			if (!this.questionForm?._orderingItems || this.questionForm._orderingItems.length <= 2) return
			this.questionForm._orderingItems.splice(index, 1)
		},
		moveInteractiveOrderingItem(index, direction) {
			const items = this.interactiveEditing?.question?.config?.items || []
			const targetIndex = index + direction
			if (targetIndex < 0 || targetIndex >= items.length) return
			const moved = items.splice(index, 1)[0]
			items.splice(targetIndex, 0, moved)
			this.interactiveEditing.question.config.correctOrder = items.map(item => item.id)
		},
		addInteractiveOrderingItem() {
			const question = this.interactiveEditing?.question
			if (!question) return
			if (!Array.isArray(question.config.items)) question.config.items = []
			question.config.items.push({ id: 'ordering_' + Date.now() + '_' + question.config.items.length, text: '' })
			question.config.correctOrder = question.config.items.map(item => item.id)
		},
		removeInteractiveOrderingItem(index) {
			const question = this.interactiveEditing?.question
			if (!question?.config?.items || question.config.items.length <= 2) return
			question.config.items.splice(index, 1)
			question.config.correctOrder = question.config.items.map(item => item.id)
		},
		openAddQuestion(level = null) {
			if (!this.selectedMon) return this.notify('Vui lòng chọn Khối/Môn trước.', 'warning')
			if (!this.selectedGroup?.Id) return this.notify('Vui lòng tạo và chọn nhóm câu hỏi trước.', 'warning')
			this.questionForm = this.createQuestionForm({ GroupId: this.selectedGroup?.Id || null })
			// Chỉ gán mức khi cấp hiện tại còn dùng taxonomy; Tiểu học mở form không kèm mapping mức độ.
			if (!this.isPrimarySchoolContext && level?.KyNang_MonHoc_ChiTietID) this.questionForm._skillIds = [level.KyNang_MonHoc_ChiTietID]
			this.blankInputs = {}
			this.dialogQuestion = true
		},
		openEditQuestion(question) {
			this.questionForm = this.createQuestionForm(question)
			this.blankInputs = {}
			this.dialogQuestion = true
		},
		createDefaultQuestionMedia() {
			return {
				type: 'YOUTUBE',
				sourceYT: { id: '', name: '', source: '' },
				sourceRecord: { id: '', name: '', source: '' },
				sourceFiles: { file: [], image: [], _url: '' },
			}
		},
		normalizeQuestionMedia(media) {
			const defaults = this.createDefaultQuestionMedia()
			const value = media && typeof media === 'object' ? media : {}
			const sourceFiles = value.sourceFiles || {}
			return {
				...defaults,
				...value,
				sourceYT: { ...defaults.sourceYT, ...(value.sourceYT || {}) },
				sourceRecord: { ...defaults.sourceRecord, ...(value.sourceRecord || {}) },
				sourceFiles: { ...defaults.sourceFiles, ...sourceFiles, file: Array.isArray(sourceFiles.file) ? sourceFiles.file : [], image: Array.isArray(sourceFiles.image) ? sourceFiles.image : [] },
			}
		},
		hasMediaObject(media) {
			if (!media) return false
			return Boolean(media.sourceYT?.source || media.sourceRecord?.source
				|| media.sourceFiles?._url
				|| media.sourceFiles?.file?.length
				|| media.sourceFiles?.image?.length)
		},
		// Link media nhập từ AI/import có thể là URL tuyệt đối hoặc metadata FileData; chỉ lấy đúng source để preview/mở file.
		getQuestionMediaSource(file, mediaKind = '') {
			const source = String(file?.externalSource || file?.source || '').trim()
			// Media ảnh cũ từng lưu source là Drive /preview; nếu còn fileId LMS thì chuyển sang URL binary để không bị spinner vô hạn.
			if (mediaKind === 'image' && file?.id && /drive\.google\.com\/file\/d\/[^/]+\/preview/i.test(source)) {
				const base = String(this.vueData?.v_Set?.urlReadFile || this.vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms/').replace(/\/$/, '')
				return `${base}/FileData/${encodeURIComponent(file.id)}`
			}
			return source
		},
		// Ảnh Content Hub được lưu cả LMS và Drive; Drive dùng cho quản lý/xóa, còn thumbnail phải đọc binary từ LMS thay vì URL /preview dạng HTML.
		getQuestionImageSource(item) {
			const meta = this.getMeta(item)
			const rawUrl = item?.dbUrl || item?.DBUrl || item?.FileURL || item?.FileUrl || meta.dbUrl || meta.DB_URL || meta.FILE_URL || meta.fileUrl || ''
			if (!rawUrl) return this.getFileUrl(item)
			if (/^https?:\/\//i.test(rawUrl)) return rawUrl
			if (/^\/\//.test(rawUrl)) return 'https:' + rawUrl
			const base = String(this.vueData?.v_Set?.urlReadFile || this.vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms/').replace(/\/$/, '')
			return `${base}/${String(rawUrl).replace(/^\//, '')}`
		},
		// Chỉ nhúng URL YouTube hợp lệ; link video khác vẫn được hiển thị thành link để tránh iframe lỗi.
		getQuestionYoutubeEmbedUrl(url) {
			const value = String(url || '').trim()
			const match = value.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{6,})/i)
			return match ? `https://www.youtube.com/embed/${match[1]}` : ''
		},
		selectQuestionMedia(item) {
			const media = this.questionForm?._media
			if (!media) return
			// Vuetify phát null khi người dùng bấm clearable; phải xóa đúng vùng media đang chọn để preview không còn giữ link cũ.
			if (!item) {
				if (media.type === 'YOUTUBE') media.sourceYT = { id: '', name: '', source: '' }
				else if (media.type === 'RECORD_AUDIO') media.sourceRecord = { id: '', name: '', source: '' }
				else media.sourceFiles = { file: [], image: [], _url: '' }
				return
			}
			const name = item.displayName || item.TenNoiDung || 'Tài liệu'
			if (media.type === 'YOUTUBE') {
				const source = this.getFileUrl(item)
				if (!source) return this.notify('Tài liệu này chưa có đường dẫn để gắn vào câu hỏi.', 'warning')
				media.sourceYT = { id: item._meta?.videoId || '', name, source }
			} else if (media.type === 'RECORD_AUDIO') {
				const source = this.getFileUrl(item)
				if (!source) return this.notify('Tài liệu này chưa có đường dẫn để gắn vào câu hỏi.', 'warning')
				media.sourceRecord = { id: item._meta?.driveFileId || item._meta?.fileId || '', name, source }
			} else {
				const isImage = /image|\.(?:png|jpe?g|gif|webp|svg|bmp)(?:[?#].*)?$/i.test(`${item.contentType || ''} ${name} ${item.fileUrl || ''}`)
				const source = isImage ? this.getQuestionImageSource(item) : this.getFileUrl(item)
				if (!source) return this.notify('Tài liệu này chưa có đường dẫn để gắn vào câu hỏi.', 'warning')
				const target = { id: item._meta?.fileId || item._meta?.driveFileId || '', name, source, mediaSource: 'content-hub' }
				if (isImage) media.sourceFiles.image = [target]
				else media.sourceFiles.file = [target]
				}
		},
		// Chỉ gỡ liên kết trong câu hỏi; tài liệu gốc vẫn giữ nguyên trong kho Tài liệu để các câu hỏi khác tiếp tục dùng được.
		clearQuestionMedia(type) {
			const media = this.questionForm?._media
			if (!media) return
			if (type === 'YOUTUBE') media.sourceYT = { id: '', name: '', source: '' }
			else if (type === 'RECORD_AUDIO') media.sourceRecord = { id: '', name: '', source: '' }
		},
		// Ảnh và tệp có thể gắn nhiều tài liệu; xóa đúng phần tử theo bucket/index để không làm mất các liên kết còn lại.
		removeQuestionMediaFile(bucketName, index) {
			const bucket = this.questionForm?._media?.sourceFiles?.[bucketName]
			if (!Array.isArray(bucket) || index < 0 || index >= bucket.length) return
			bucket.splice(index, 1)
		},
		// File/ảnh nhập bằng link được phân loại theo phần mở rộng để giữ đúng schema sourceFiles.file/image của Soạn bài tập.
		addQuestionFileLink() {
			const media = this.questionForm?._media
			const url = String(media?.sourceFiles?._url || '').trim()
			if (!url) return
			const isImage = /\.(?:png|jpe?g|gif|webp|svg|bmp)(?:[?#].*)?$/i.test(url)
			const bucket = isImage ? media.sourceFiles.image : media.sourceFiles.file
			if (!bucket.some(file => file?.source === url || file?.externalSource === url)) bucket.push({ id: '', name: url, source: url, mediaSource: 'link' })
			media.sourceFiles._url = ''
		},
		serializeQuestionMedia(media) {
			const normalized = this.normalizeQuestionMedia(media)
			const sourceFiles = { ...normalized.sourceFiles }
			const linkedUrl = String(sourceFiles._url || '').trim()
			delete sourceFiles._url
			if (linkedUrl && !sourceFiles.file.some(file => file?.source === linkedUrl)) {
				sourceFiles.file = [...sourceFiles.file, { id: '', name: linkedUrl, source: linkedUrl, mediaSource: 'link' }]
			}
			return { ...normalized, sourceFiles }
		},
		getQuestionConfig(question) {
			return this.parseJson(question?.ConfigJson, {})
		},
		escapeQuestionDisplayText(value) {
			// Ngân hàng câu hỏi phải hiển thị mã HTML nguyên văn; escape trước khi đưa vào v-html để không tạo DOM từ dữ liệu import.
			return String(value ?? '').replace(/<!--[\s\S]*?-->|<!DOCTYPE[^>]*>|<\/?[A-Za-z][^>]*>/gi, tag => tag.replace(/</g, '&lt;').replace(/>/g, '&gt;'))
		},
		stripQuestionEditorWrappers(value) {
			// Rich-text editor thường bọc mọi nội dung bằng một cặp <p>/<div>; bỏ wrapper này trước khi hiển thị mã HTML của môn Tin học để không lộ tag kỹ thuật của editor.
			return String(value ?? '')
				.replace(/^\s*<(?:p|div)(?:\s[^>]*)?>/i, '')
				.replace(/<\/(?:p|div)>\s*$/i, '')
		},
		getQuestionDisplayContent(value) {
			const text = this.normalizeQuestionFieldText(value)
			// Ngoài môn Tin học, uc-latex-view được phép render rich-text an toàn; riêng Tin học mới escape mã HTML để <h1>, <!-- -->... hiện như chữ.
			return this.isComputerSubjectContext ? this.escapeQuestionDisplayText(this.stripQuestionEditorWrappers(text)) : text
		},
		getQuestionText(question) {
			const config = this.getQuestionConfig(question)
			return question?.QuestionText || config.questionText || config.prompt || ''
		},
		// Tên file được lưu trong sourceTracking từ lúc import; fallback giúp dữ liệu cũ vẫn có nhãn truy vết dễ hiểu.
		getQuestionSourceFile(question) {
			const config = this.getQuestionConfig(question)
			const raw = this.parseJson(question?.RawJson, {})
			const tracking = config?.sourceTracking || {}
			const candidates = [
				question?.SourceFileName,
				question?.FileName,
				question?.TenFile,
				question?._sourceFileName,
				tracking.sourceFileName,
				tracking.fileName,
				config.sourceFileName,
				raw?.sourceFileName,
				raw?.fileName,
				raw?.FileName,
			]
			const sourceName = candidates.find(value => String(value || '').trim())
			if (sourceName) return String(sourceName).trim()
			const sourceId = String(question?.SourceId || '')
			if (/^FILE_IMPORT_/i.test(sourceId)) return 'File import cũ (chưa lưu tên)'
			if (/^HOC_LIEU_SO_/i.test(sourceId)) return 'Học liệu nguồn (chưa lưu tên)'
			if (/^question_/i.test(sourceId)) return 'Tạo thủ công'
			return 'Chưa xác định'
		},
		hasQuestionMedia(question) {
			return this.hasMediaObject(this.getQuestionConfig(question).media)
		},
		getQuestionAnswerItems(question) {
			const config = this.getQuestionConfig(question)
			const type = question?.Type || question?.type || ''
			const options = Array.isArray(config.options) ? config.options : []
			// Import schema lưu đáp án đúng bằng option id; fallback về giá trị gốc để dữ liệu cũ hoặc AI trả text vẫn hiển thị được.
			const valueToText = value => {
				if (value === null || value === undefined) return ''
				if (typeof value === 'object') return String(value.text ?? value.content ?? value.label ?? value.value ?? '')
				return String(value)
			}
			const hasValue = value => value !== null && value !== undefined && value !== ''
			const optionText = value => {
				const option = options.find(item => String(item?.id) === String(value))
				return valueToText(option || value)
			}
			const getOptionLetter = (optionId, fallbackIdx) => {
				const idStr = String(optionId || '').trim()
				// Nếu id là 'a', 'b', 'c', 'd' hoặc 'A', 'B', 'C', 'D'
				if (/^[a-z]$/i.test(idStr)) return idStr.toUpperCase()
				// Tìm index trong danh sách options
				const idx = options.findIndex(item => String(item?.id) === idStr)
				if (idx !== -1) return String.fromCharCode(65 + idx)
				if (typeof fallbackIdx === 'number' && fallbackIdx >= 0) return String.fromCharCode(65 + fallbackIdx)
				return ''
			}

			if (type === 'QUIZ_SINGLE_CHOICE') {
				if (!hasValue(config.correctAnswer)) return []
				const letter = getOptionLetter(config.correctAnswer, 0)
				const label = letter ? `Đáp án đúng ${letter}` : 'Đáp án đúng'
				return [{ label, text: optionText(config.correctAnswer) }]
			}
			if (type === 'QUIZ_MULTIPLE_CHOICE') {
				const correctAnswers = Array.isArray(config.correctAnswers) ? config.correctAnswers : []
				return correctAnswers.map((id, index) => {
					const letter = getOptionLetter(id, index)
					const label = letter ? `Đáp án đúng ${letter}` : `Đáp án đúng (${index + 1})`
					return { label, text: optionText(id) }
				}).filter(item => item.text)
			}
			if (type === 'QUIZ_TRUE_FALSE') {
				if (options.length) return options.map((option, index) => {
					const letter = String.fromCharCode(65 + index)
					const answer = option?.correctAnswer === true || option?.correctAnswer === 'true' || option?.correctAnswer === 1 ? 'Đúng' : (option?.inCorrectAnswer ? 'Sai' : '')
					return answer ? { label: `Mệnh đề ${letter} (${answer})`, text: option.text || '' } : null
				}).filter(Boolean)
				if (config.correctAnswer === true || config.correctAnswer === 'true' || config.correctAnswer === 1) return [{ label: 'Đáp án đúng', text: 'Đúng' }]
				if (config.correctAnswer === false || config.correctAnswer === 'false' || config.correctAnswer === 0) return [{ label: 'Đáp án đúng', text: 'Sai' }]
			}
			if (type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
				return options.map((option, index) => {
					const letter = String.fromCharCode(65 + index)
					const answer = option?.correctAnswer === true || option?.correctAnswer === 'true' || option?.correctAnswer === 1 ? 'Đúng' : (option?.inCorrectAnswer ? 'Sai' : '')
					return answer ? { label: `Mệnh đề ${letter} (${answer})`, text: option.text || '' } : null
				}).filter(Boolean)
			}
			if (type === 'QUIZ_FILL_IN_BLANK') {
				return (Array.isArray(config.parts) ? config.parts : []).filter(part => part?.type === 'blank').map((part, index) => ({ label: 'Chỗ trống ' + (index + 1), text: Array.isArray(part.acceptedAnswers) ? part.acceptedAnswers.join(' / ') : (part.correctAnswer || '') })).filter(item => item.text)
			}
			if (type === 'QUIZ_MATCHING') {
				const columnA = Array.isArray(config.columnA) ? config.columnA : []
				const columnB = Array.isArray(config.columnB) ? config.columnB : []
				return (Array.isArray(config.correctPairs) ? config.correctPairs : []).map((pair, index) => ({ label: 'Cặp ' + (index + 1), text: (columnA.find(item => String(item?.id) === String(pair?.from))?.text || '') + ' → ' + (columnB.find(item => String(item?.id) === String(pair?.to))?.text || '') })).filter(item => item.text !== ' → ')
			}
			if (type === 'QUIZ_ORDERING') {
				const items = Array.isArray(config.items) ? config.items : []
				const itemById = new Map(items.map(item => [String(item?.id), item]))
				const order = Array.isArray(config.correctOrder) && config.correctOrder.length ? config.correctOrder : items.map(item => item?.id)
				return order.map((id, index) => ({
					label: 'Thứ tự ' + (index + 1),
					text: valueToText(itemById.get(String(id))),
				})).filter(item => item.text)
			}
			const fallbackAnswer = hasValue(config.correctAnswer) ? config.correctAnswer : config.answer
			return hasValue(fallbackAnswer) ? [{ label: 'Đáp án đúng', text: valueToText(fallbackAnswer) }] : []
		},
		buildQuestionConfig(questionTextOverride = null) {
			const form = this.questionForm
			const questionText = questionTextOverride === null ? this.getQuestionTextForSave() : this.normalizeQuestionFieldText(questionTextOverride)
			const baseConfig = { ...this.parseJson(form.ConfigJson, {}), questionText, isAdvanced: Boolean(form._isAdvanced), media: this.serializeQuestionMedia(form._media) }
			if (['SHORT_ANSWER', 'ESSAY'].includes(form.Type)) {
				// Chỉ câu chấm tay mới lưu referenceAnswer; các dạng quiz không nhận key này để tránh hiểu nhầm là đáp án tự động.
				baseConfig.referenceAnswer = this.normalizeQuestionFieldText(form._referenceAnswer || '')
			} else {
				delete baseConfig.referenceAnswer
			}
			if (this.isPrimarySchoolContext) {
				// Dọn các khóa mức độ cũ khi sửa câu hỏi Tiểu học, tránh ẩn giao diện nhưng vẫn giữ mapping trong ConfigJson.
				delete baseConfig.questionLevel; delete baseConfig.QuestionLevel; delete baseConfig.MucDo; delete baseConfig.MucDoCode; delete baseConfig.Level; delete baseConfig.LevelCode
			}
			if (form.Type === 'QUIZ_SINGLE_CHOICE' || form.Type === 'QUIZ_MULTIPLE_CHOICE') {
				const options = form._options.map((text, index) => {
					// Ở chế độ Nâng cao, text được lưu trực tiếp từ uc-latex-edit
					if (form._isAdvanced) {
						return { id: String.fromCharCode(97 + index), text: text || '' }
					}
					const plainText = this.normalizeQuestionFieldText(form._plainOptions?.[index] ?? text)
					return { id: String.fromCharCode(97 + index), text: plainText }
				})
				const config = { ...baseConfig, options }
				if (form.Type === 'QUIZ_SINGLE_CHOICE') config.correctAnswer = options[form._correctIndex]?.id || null
				if (form.Type === 'QUIZ_MULTIPLE_CHOICE') config.correctAnswers = form._correctIndexes.map(index => options[index]?.id).filter(Boolean)
				return config
			}
			if (form.Type === 'QUIZ_TRUE_FALSE') {
				if (form._tfOptions && form._tfOptions.length) {
					const options = form._tfOptions.map((opt, index) => ({
						id: String.fromCharCode(97 + index),
						text: opt.text || '',
						correctAnswer: Boolean(opt.correctAnswer),
						inCorrectAnswer: Boolean(opt.inCorrectAnswer),
					}))
					return { ...baseConfig, options }
				}
				return { ...baseConfig, correctAnswer: Boolean(form._tfAnswer) }
			}
			if (form.Type === 'QUIZ_MULTIPLE_TRUE_FALSE') {
				const options = (form._tfOptions || []).map((opt, index) => ({
					id: String.fromCharCode(97 + index),
					text: opt.text || '',
					correctAnswer: Boolean(opt.correctAnswer),
					inCorrectAnswer: Boolean(opt.inCorrectAnswer),
				}))
				// Bốn mệnh đề là quy ước chấm từng ý; không phụ thuộc trạng thái UI cũ bị thiếu scoringMode.
				const scoringMode = options.length === 4 ? 'partial' : (form._tfScoringMode || 'equal')
				return { ...baseConfig, options, scoringMode }
			}
			if (form.Type === 'QUIZ_FILL_IN_BLANK') {
				const parts = (form._blankParts || []).map((p, idx) => {
					if (p.type === 'blank') {
						const acceptedAnswers = Array.isArray(p.acceptedAnswers)
							? p.acceptedAnswers.map(answer => String(answer).trim()).filter(Boolean)
							: String(p.correctAnswer || '').split('/').map(answer => answer.trim()).filter(Boolean)
						return { type: 'blank', id: p.id || ('blank_' + idx), correctAnswer: acceptedAnswers[0] || '', acceptedAnswers }
					}
					return { type: 'text', value: p.value || '' }
				})
				return { ...baseConfig, parts }
			}
			if (form.Type === 'QUIZ_MATCHING') {
				const pairs = form._matchingPairs || []
				const columnA = pairs.map((p, idx) => ({ id: 'a_' + idx, text: p.left || '' }))
				const columnB = pairs.map((p, idx) => ({ id: 'b_' + idx, text: p.right || '' }))
				const correctPairs = pairs.map((p, idx) => ({ from: 'a_' + idx, to: 'b_' + idx }))
				return { ...baseConfig, columnA, columnB, correctPairs }
			}
			if (form.Type === 'QUIZ_ORDERING') {
				// Thứ tự trên form là đáp án đúng; lưu đồng thời nội dung và ID order để các module khác không phải đoán theo text.
				const items = (form._orderingItems || []).map((item, index) => ({
					id: String(item?.id || ('ordering_' + (index + 1))),
					text: this.isComputerSubjectContext ? (item?.text || '') : this.normalizeQuestionFieldText(item?.text || ''),
				}))
				return { ...baseConfig, items, correctOrder: items.map(item => item.id), scoringMode: 'equal' }
			}
			return baseConfig
		},
		async saveQuestion() {
			const questionText = this.getQuestionTextForSave()
			if (!this.selectedMon || !this.questionForm.Type || !questionText) return this.notify('Vui lòng nhập Khối/Môn, loại và nội dung câu hỏi.', 'warning')
			this.savingQuestion = true
			try {
				if (!this.questionForm.GroupId) this.questionForm.GroupId = await this.ensureQuestionGroup()
				const isEdit = Boolean(this.questionForm.Id)
				const questionConfig = this.buildQuestionConfig(questionText)
				if (this.questionForm.Type === 'QUIZ_ORDERING') {
					const items = Array.isArray(questionConfig.items) ? questionConfig.items : []
					if (items.length < 2 || items.some(item => !this.normalizeQuestionFieldText(item?.text).trim())) {
						return this.notify('Câu sắp xếp phải có ít nhất 2 ý và không được để trống.', 'warning')
					}
				}
				const payload = {
					...(isEdit ? { Id: this.questionForm.Id, OrdinalNumber: this.questionForm.OrdinalNumber ?? null } : {}), GroupId: this.questionForm.GroupId || null,
					SourceId: this.questionForm.SourceId || ('question_' + Date.now()), Type: this.questionForm.Type, QuestionText: questionText,
					Points: this.normalizeEditableQuestionPoints(this.questionForm.Points), GradingType: this.questionForm.Type === 'QUIZ_ORDERING' ? 'auto' : (this.questionForm.GradingType || 'auto'), IsAdvanced: this.questionForm._isAdvanced ? 1 : 0,
					// Không lưu lại mapping mức độ cũ khi sửa/tạo câu hỏi cho Tiểu học.
					ConfigJson: JSON.stringify(questionConfig), SkillsJson: JSON.stringify(this.isPrimarySchoolContext ? [] : (this.questionForm._skillIds || []).map(id => this.serializeQuestionSkill(id)).filter(Boolean)), RawJson: this.questionForm.RawJson || null, User: this.vueData.user?.UserID,
				}
				const result = await fetchPromise('lms/EL_Question_' + (isEdit ? 'Update' : 'Create'), payload, { cache: false })
				if (!this.isApiSuccess(result)) return this.notify('Không thể lưu câu hỏi.', 'error')
				this.dialogQuestion = false
				
				// Nâng cao UX: Với câu hỏi đang sửa, cập nhật trực tiếp tại chỗ trong DSQuestion và chớp sáng dòng để không làm gián đoạn vị trí cuộn của người dùng.
				if (isEdit) {
					const savedId = String(this.questionForm.Id || this.questionForm.ID || '')
					const idx = this.DSQuestion.findIndex(q => String(q.raw?.Id || q.Id || q.ID) === savedId)
					if (idx !== -1) {
						this.DSQuestion.splice(idx, 1, {
							...this.DSQuestion[idx],
							QuestionText: questionText,
							Type: this.questionForm.Type,
							Points: this.normalizeEditableQuestionPoints(this.questionForm.Points),
							GradingType: this.questionForm.Type === 'QUIZ_ORDERING' ? 'auto' : (this.questionForm.GradingType || 'auto'),
							IsAdvanced: this.questionForm._isAdvanced ? 1 : 0,
							ConfigJson: payload.ConfigJson,
							UpdateTime: new Date().toISOString().replace('T', ' ').slice(0, 19),
						})
					}
					this.highlightQuestionRow(savedId)
					this.notify('Đã cập nhật câu hỏi.')
					// Đồng bộ ngầm với server mà vẫn giữ nguyên vị trí scroll
					await this.loadQuestions({ silent: true, preserveScroll: true })
				} else {
					await this.loadQuestions({ silent: false, preserveScroll: false })
					this.notify('Đã tạo câu hỏi.')
				}
			} finally { this.savingQuestion = false }
		},
		async deleteQuestion(question) {
			const ok = await this.confirmRef?.value?.show?.({ title: 'Xóa câu hỏi này?' })
			if (!ok) return
			const result = await fetchPromise('lms/EL_Question_Delete', { Id: question.Id, User: this.vueData.user?.UserID }, { cache: false })
			if (!this.isApiSuccess(result)) return this.notify('Không thể xóa câu hỏi.', 'error')
			this.selectedQuestions = this.selectedQuestions.filter(id => (typeof id === 'object' ? id.Id : id) !== question.Id)
			// Xóa trực tiếp tại chỗ trong mảng để bảng không bị reload giật cuộn lên đầu
			const idx = this.DSQuestion.findIndex(q => q.Id === question.Id)
			if (idx !== -1) this.DSQuestion.splice(idx, 1)
			this.notify('Đã xóa câu hỏi.')
			// Đồng bộ ngầm với server
			await this.loadQuestions({ silent: true, preserveScroll: true })
		},
		isContentHubDocument(item) {
			return String(item?.NguonTaiNguyenCode || item?.sourceLabel || item?._meta?.origin || '').toUpperCase() === 'CONTENT_HUB'
		},
		async deleteGitHubPath(path, config) {
			const encodedPath = path.split('/').map(part => encodeURIComponent(part)).join('/')
			const branch = config.branch || 'main'
			const response = await fetch('https://api.github.com/repos/' + config.owner + '/' + config.repo + '/contents/' + encodedPath + '?ref=' + encodeURIComponent(branch), {
				headers: { Authorization: 'token ' + config.token, Accept: 'application/vnd.github.v3+json' },
			})
			if (response.status === 404) return
			if (!response.ok) throw new Error('Không thể đọc nội dung iSpring trên GitHub.')
			const payload = await response.json()
			const entries = Array.isArray(payload) ? payload : []
			for (const entry of entries) {
				if (entry.type === 'dir') await this.deleteGitHubPath(entry.path, config)
				else {
					const deleteResponse = await fetch('https://api.github.com/repos/' + config.owner + '/' + config.repo + '/contents/' + entry.path.split('/').map(part => encodeURIComponent(part)).join('/'), {
						method: 'DELETE',
						headers: { Authorization: 'token ' + config.token, Accept: 'application/vnd.github.v3+json', 'Content-Type': 'application/json' },
						body: JSON.stringify({ message: 'Delete iSpring ' + entry.name, sha: entry.sha, branch }),
					})
					if (!deleteResponse.ok && deleteResponse.status !== 404) throw new Error('Không thể xóa tệp iSpring trên GitHub.')
				}
			}
		},
		async deleteExternalDocument(item) {
			const meta = item?._meta || {}
			const isManagedDriveFile = meta.uploadSource === 'ggdrive' && meta.driveFileId && (meta.externalManaged === true || Number(meta.fileSize || 0) > 0)
			const isManagedYoutubeVideo = meta.uploadSource === 'youtube' && meta.videoId
			const isManagedISpring = meta.uploadSource === 'github-ispring' && meta.iSpringGUID
			// Link người dùng dán vào không có quyền sở hữu; chỉ xóa tài nguyên bên ngoài do Content Hub tự phát hành.
			if (isManagedYoutubeVideo) {
				const token = await fetchPromise('lms/FP_Youtube_Token_Get')
				if (!token?.access_token || !window.UploadManager?.deleteFromYouTube) throw new Error('Không lấy được quyền xóa video YouTube.')
				await new Promise((resolve, reject) => window.UploadManager.deleteFromYouTube(meta.videoId, { accessToken: token.access_token, onComplete: resolve, onError: reject }))
			}
			if (isManagedDriveFile) {
				const token = await fetchPromise('lms/FP_Youtube_Token_Get')
				if (!token?.access_token || !window.UploadManager?.deleteFromGoogleDrive) throw new Error('Không lấy được quyền xóa file Google Drive.')
				try {
					await new Promise((resolve, reject) => window.UploadManager.deleteFromGoogleDrive(meta.driveFileId, { accessToken: token.access_token, onComplete: resolve, onError: reject }))
				} catch (error) {
					const status = Number(error?.status || error?.statusCode || error?.response?.status || error?.code || 0)
					const message = String(error?.message || error?.response?.data?.error?.message || error || '')
					if (status !== 404 && !/file not found/i.test(message)) throw error
					// File gốc đã bị xóa/không còn quyền truy cập; tiếp tục dọn bản ghi trong Content Hub.
					console.warn('Google Drive file không còn tồn tại, bỏ qua bước xóa:', meta.driveFileId)
				}
			}
			if (isManagedISpring) {
				const config = await fetchPromise('lms/FP_Github_Config_Get')
				if (!config?.token || !config.owner || !config.repo) throw new Error('Chưa có cấu hình GitHub để xóa iSpring.')
				await this.deleteGitHubPath('content/' + meta.iSpringGUID, config)
			}
		},
		async deleteDocument(item) {
			if (this.deletingDocumentId || !this.isContentHubDocument(item) || !item?.NoiDungID) return
			if (this.isProfileInspectionMode || this.isInitiativeInspectionMode) return this.notify('Chế độ giám sát không thể xóa tài liệu của giáo viên.', 'warning')
			// Chặn cả UI lẫn lời gọi trực tiếp trong component; không tin vào việc nút xóa đã bị ẩn.
			if (!this.isContentOwner(item)) return this.notify('Chỉ người tải lên mới được xóa file này.', 'warning')
			const ok = await this.confirmRef?.value?.show?.({ title: 'Xóa tài liệu "' + (item.displayName || '') + '" khỏi kho?' })
			if (!ok) return
			this.deletingDocumentId = item.NoiDungID
			try {
				// Xóa tài nguyên ngoài trước; nếu thất bại thì giữ node để người dùng có thể thử lại, tránh tạo liên kết mồ côi.
				await this.deleteExternalDocument(item)
				// Node_Delete đánh dấu node đã xóa; phía server dọn cả dbo.FileData hoặc LMS-LHBS-file khi file không còn được tham chiếu.
				const result = await fetchPromise('lms/FP_TaiNguyen_Node_Delete', { NoiDungID: item.NoiDungID, User: this.getCurrentUserId() }, { cache: false })
				if (!this.isApiSuccess(result)) return this.notify('Không thể xóa tài liệu khỏi kho.', 'error')
				if (this.activeBranch === 'initiative') await this.loadInnovationResources()
				else if (this.selectedLibraryId) await this.loadTree()
				await this.loadSourceFiles()
				this.notify('Đã xóa tài liệu khỏi kho.')
			} catch (error) {
				this.notify(error?.message || 'Không thể xóa tài liệu khỏi kho.', 'error')
			} finally {
				this.deletingDocumentId = null
			}
		},
		// Xóa hàng loạt các câu hỏi đã được tích checkbox
		async deleteSelectedQuestions() {
			const count = this.selectedQuestions.length
			if (!count) return
			const ok = await this.confirmRef?.value?.show?.({ title: `Bạn có chắc chắn muốn xóa ${count} câu hỏi đã chọn?` })
			if (!ok) return
			this.deletingMultipleQuestions = true
			try {
				let deletedCount = 0
				for (const item of this.selectedQuestions) {
					const questionId = typeof item === 'object' ? item.Id : item
					const res = await fetchPromise('lms/EL_Question_Delete', { Id: questionId, User: this.vueData.user?.UserID }, { cache: false })
					if (this.isApiSuccess(res)) deletedCount++
				}
				this.selectedQuestions = []
				await this.loadQuestions()
				this.notify(`Đã xóa thành công ${deletedCount}/${count} câu hỏi.`)
			} catch (error) {
				this.notify('Có lỗi xảy ra khi xóa danh sách câu hỏi.', 'error')
			} finally {
				this.deletingMultipleQuestions = false
			}
		},
		removeQuestionOption(index) {
			this.questionForm._options.splice(index, 1)
			this.questionForm._plainOptions.splice(index, 1)
			this.questionForm._correctIndexes = this.questionForm._correctIndexes.filter(value => value !== index).map(value => value > index ? value - 1 : value)
			if (this.questionForm._correctIndex === index) this.questionForm._correctIndex = 0
			if (this.questionForm._correctIndex > index) this.questionForm._correctIndex -= 1
		},
		async openImportHocLieu() {
			if (!this.selectedMon) return this.notify('Vui lòng chọn Khối/Môn trước.', 'warning')
			this.importSourceType = 'HOC_LIEU_SO'; this.importSourceFileName = ''; this.importDefaultSkillIds = []
			this.dialogImport = true; this.importLoading = true; this.importError = ''; this.importQuestions = []
			try {
				const result = await fetchPromise('lms/EL_Teacher_GetQuestionFromHocLieu', { MonHocID: this.selectedMon.MonHocID, KhoiID: this.selectedMon.KhoiID }, { forceRefresh: true, useStaleCacheOnError: false })
				const data = Array.isArray(result?.data) ? result.data : (Array.isArray(result) ? result : [])
				this.importQuestions = this.normalizeHocLieuQuestions(data[1] || [], data[0] || []).map(question => ({ ...question, _skillIds: this.resolveImportedSkillIds(question) }))
			} catch (error) { this.importError = 'Không tải được danh sách câu hỏi từ học liệu số.' }
			finally { this.importLoading = false }
		},
		openQuestionFilePicker(level = null) {
			if (!this.selectedGroup?.Id) return this.notify('Vui lòng tạo và chọn nhóm câu hỏi trước.', 'warning')
			// Chỉ ghi nhớ mức đích ở các cấp còn dùng taxonomy; Tiểu học luôn import không gán mức.
			this.pendingQuestionLevelId = !this.isPrimarySchoolContext ? (level?.KyNang_MonHoc_ChiTietID || null) : null
			this.importDefaultSkillIds = this.pendingQuestionLevelId ? [this.pendingQuestionLevelId] : []
			this.$refs.questionFileInput?.click()
		},
		openImportJsonPicker(level = null) {
			if (!this.selectedGroup?.Id) return this.notify('Vui lòng tạo và chọn nhóm câu hỏi trước.', 'warning')
			this.pendingQuestionLevelId = !this.isPrimarySchoolContext ? (level?.KyNang_MonHoc_ChiTietID || null) : null
			this.importDefaultSkillIds = this.pendingQuestionLevelId ? [this.pendingQuestionLevelId] : []
			this.jsonImportText = ''
			this.jsonImportFileName = ''
			this.dialogImportJson = true
		},
		onJsonFileSelected(event) {
			const file = event?.target?.files?.[0]
			if (event?.target) event.target.value = ''
			if (!file) return
			this.jsonImportFileName = file.name
			const reader = new FileReader()
			reader.onload = (e) => {
				this.jsonImportText = e.target?.result || ''
			}
			reader.readAsText(file, 'utf-8')
		},
		normalizeQuestionPoints(value) {
			// Môn Tin học dùng một thang điểm cố định cho mỗi câu; áp dụng ở một điểm chung để dữ liệu cũ, tạo mới và mọi luồng import không lệch nhau.
			if (this.isComputerSubjectContext) return 0.25
			const points = Number(value)
			return Number.isFinite(points) && points > 0 ? points : 1
		},
		normalizeEditableQuestionPoints(value) {
			// Form thủ công vẫn cho phép điều chỉnh điểm; chỉ dùng 0.25 làm giá trị mặc định khi ô bị bỏ trống.
			const normalized = Number(String(value ?? '').trim().replace(',', '.'))
			return Number.isFinite(normalized) && normalized > 0 ? normalized : (this.isComputerSubjectContext ? 0.25 : 1)
		},
		async processImportJson() {
			const parsed = this.parsedJsonImportData
			if (!parsed || !parsed.questions || !parsed.questions.length) {
				return this.notify('Dữ liệu JSON không hợp lệ hoặc không tìm thấy câu hỏi nào.', 'warning')
			}
			const questions = parsed.questions
			const filename = parsed.filename || this.jsonImportFileName || 'Dữ liệu JSON'
			this.dialogImportJson = false
			this.importSourceType = 'JSON_IMPORT'
			this.importSourceFileName = filename
			const pendingLevelId = this.pendingQuestionLevelId
			this.importDefaultSkillIds = pendingLevelId ? [pendingLevelId] : []
			this.importLoading = false
			this.importQuestions = questions.map((question, index) => {
				const type = question.type || 'QUIZ_SINGLE_CHOICE'
				const content = question.content || question.config || {}
				const questionText = content.prompt || content.questionText || question.questionText || 'Câu hỏi import từ JSON'
				const mathOrHtmlRegex = /(\$|\\\(|\\\[|\\begin\{|<math|<[a-z][\s\S]*>|data:image\/|&[a-z]+;)/i
				const rawOpts = Array.isArray(content.options) ? content.options : (Array.isArray(question.options) ? question.options : [])
				const hasAdvancedContent = mathOrHtmlRegex.test(questionText) || rawOpts.some(opt => {
					const text = typeof opt === 'object' ? (opt?.text ?? opt?.content ?? opt?.value ?? '') : String(opt || '')
					return mathOrHtmlRegex.test(text)
				})
				const apiIsAdvanced = content.isAdvanced ?? content.IsAdvanced ?? question.isAdvanced ?? question.IsAdvanced ?? question.config?.isAdvanced ?? question.config?.IsAdvanced
				const isAdvanced = apiIsAdvanced === true || apiIsAdvanced === 'true' || apiIsAdvanced === 1 || hasAdvancedContent
				const normalized = {
					...question,
					_key: 'JSON_' + Date.now() + '_' + index,
					_content: { ...content, prompt: questionText, questionText, isAdvanced, media: this.normalizeQuestionMedia(content.media) },
					TenNoiDung: questionText,
					LoaiNoiDung: type,
					Points: this.normalizeQuestionPoints(question.points),
					_sourceFileName: filename,
					_rawQuestion: { ...question, points: this.normalizeQuestionPoints(question.points), Points: this.normalizeQuestionPoints(question.points), sourceFileName: filename },
					_selected: true,
					_supported: this.isSupportedImportType(type)
				}
				normalized._skillIds = pendingLevelId ? [pendingLevelId] : []
				return normalized
			})
			this.importError = ''
			await this.saveImportedQuestions()
		},
		fileToBase64(file) {
			return new Promise((resolve, reject) => { const reader = new FileReader(); reader.onload = () => resolve(String(reader.result).split(',')[1] || ''); reader.onerror = reject; reader.readAsDataURL(file) })
		},
		async convertQuestionFile(event) {
			const file = event?.target?.files?.[0]
			if (event?.target) event.target.value = ''
			if (!file || !this.selectedMon) return
			if (!this.selectedGroup?.Id) return this.notify('Vui lòng tạo và chọn nhóm câu hỏi trước.', 'warning')
			this.convertingFile = true
			this.convertingFileName = file.name
			try {
				// AIDocumentProcess thuộc route nội bộ lms/auth; dùng fetchPromise để đi qua apiDomain, authorization, loading và error middleware chung của LMS.
				// Tiểu học/Cấp 1 dùng prompt riêng để AI hiểu đúng cấu trúc câu hỏi; context khác giữ prompt chung hiện tại.
				const promptId = this.isPrimarySchoolContext ? 'lms-tieu-hoc-import-v1' : 'lms-content-hub-question-import-v1'
				const payload = await fetchPromise('lms/auth/AIDocumentProcess', { Action: 'CONVERT', FileName: file.name, FileBase64: await this.fileToBase64(file), PromptId: promptId }, { cache: false, useStaleCacheOnError: false })
				const row = Array.isArray(payload) ? payload[0] : (payload?.data?.[0] || payload); let data = row?.Data || row?.data || row
				if (row?.Status === 'ERROR') throw new Error(row.ErrorMessage || 'Không thể chuyển đổi file thành câu hỏi.')
				if (typeof data === 'string') { try { data = JSON.parse(data) } catch (error) {} }
				if (typeof data?.data === 'string') { try { data.data = JSON.parse(data.data) } catch (error) {} }
				const questions = data?.data?.questions || data?.questions || data?.result?.questions || []
				if (!Array.isArray(questions) || !questions.length) throw new Error('API không trả về câu hỏi nào.')
				this.importSourceType = 'DOCUMENT_FILE'
				this.importSourceFileName = file.name
				const pendingLevelId = this.pendingQuestionLevelId
				// File import luôn là luồng nhanh: có level đích thì gán thẳng vào level đó, không có thì vào group hệ thống “Chưa xác định mức độ”; không mở dialog trung gian.
				this.importDefaultSkillIds = pendingLevelId ? [pendingLevelId] : []
				this.importLoading = false
				this.importQuestions = questions.map((question, index) => {
					const type = question.type || 'QUIZ_SINGLE_CHOICE'; const content = question.content || question.config || {}
					const questionText = content.prompt || content.questionText || question.questionText || 'Câu hỏi import từ file'
					const mathOrHtmlRegex = /(\$|\\\(|\\\[|\\begin\{|<math|<[a-z][\s\S]*>|data:image\/|&[a-z]+;)/i
					const rawOpts = Array.isArray(content.options) ? content.options : (Array.isArray(question.options) ? question.options : [])
					const hasAdvancedContent = mathOrHtmlRegex.test(questionText) || rawOpts.some(opt => {
						const text = typeof opt === 'object' ? (opt?.text ?? opt?.content ?? opt?.value ?? '') : String(opt || '')
						return mathOrHtmlRegex.test(text)
					})
					const apiIsAdvanced = content.isAdvanced ?? content.IsAdvanced ?? question.isAdvanced ?? question.IsAdvanced ?? question.config?.isAdvanced ?? question.config?.IsAdvanced
					const isAdvanced = apiIsAdvanced === true || apiIsAdvanced === 'true' || apiIsAdvanced === 1 || hasAdvancedContent
					const normalizedPoints = this.normalizeQuestionPoints(question.points)
					const normalized = { ...question, _key: 'FILE_' + Date.now() + '_' + index, _content: { ...content, prompt: questionText, questionText, isAdvanced, media: this.normalizeQuestionMedia(content.media) }, TenNoiDung: questionText, LoaiNoiDung: type, Points: normalizedPoints, _sourceFileName: file.name, _rawQuestion: { ...question, points: normalizedPoints, Points: normalizedPoints, sourceFileName: file.name }, _selected: true, _supported: this.isSupportedImportType(type) }
					// Nếu user mở import từ một dòng mức độ, ưu tiên đúng mức độ đích; menu tổng luôn để trống mức độ để câu vào group hệ thống.
					normalized._skillIds = pendingLevelId ? [pendingLevelId] : []
					return normalized
				})
				this.importError = ''
				await this.saveImportedQuestions()
			} catch (error) { this.notify(`Import câu hỏi thất bại: ${error.message}`, 'error') }
			finally { this.convertingFile = false; this.convertingFileName = '' }
		},
		toggleAllImportQuestions(value) {
			// Cho phép chọn nhanh cả lô; câu hỏi không được hỗ trợ vẫn bị bỏ qua và không thể ghi vào ngân hàng.
			this.importQuestions.forEach(question => {
				if (question._supported) question._selected = Boolean(value)
			})
		},
		applyImportDefaultSkills() {
			// Kỹ năng mặc định chỉ áp dụng cho câu đang được chọn; câu không chọn vẫn giữ mapping riêng để user rà lại sau.
			const ids = [...(this.importDefaultSkillIds || [])]
			this.importQuestions.forEach(question => {
				if (question._selected && question._supported) question._skillIds = [...ids]
			})
		},
			normalizeSkillText(value) {
			return String(value || '').normalize('NFD').replace(/[\u0300-\u036f]/g, '').replace(/đ/gi, 'd').toLowerCase().replace(/\s+/g, ' ').trim()
		},
		resolveImportedSkillIds(question) {
			const candidates = []
			const collect = value => {
				if (value === null || value === undefined || value === '') return
				if (typeof value === 'number') { candidates.push(value); return }
				if (typeof value === 'string') {
					const parsed = this.parseJson(value, null)
					if (parsed !== null && parsed !== value) return collect(parsed)
					candidates.push(value)
					return
				}
				if (Array.isArray(value)) return value.forEach(collect)
				if (typeof value === 'object') {
					const id = value.KyNang_MonHoc_ChiTietID ?? value.SkillID ?? value.SkillId ?? value.MaKyNang ?? value.SkillCode ?? value.id ?? value.ID
					const name = value.TenKyNang ?? value.SkillName ?? value.skillName ?? value.name
					if (id !== undefined && id !== null) candidates.push(id)
					if (name) candidates.push(name)
					if (id === undefined && !name) Object.values(value).forEach(collect)
				}
			}
			const content = question?._content || question?.content || question?.config || {}
			collect(question?._skillIds)
			collect(question?.SkillsJson); collect(question?.SkillIds); collect(question?.SkillID); collect(question?.SkillCode); collect(question?.SkillName); collect(question?.MucDo); collect(question?.MucDoCode); collect(question?.Level); collect(question?.LevelCode)
			collect(content.skills || content.Skills || content.skill || content.skillIds || content.SkillIds || content.SkillsJson || content.skillCode || content.SkillCode || content.skillName || content.SkillName || content.mucDo || content.MucDo || content.mucDoCode || content.MucDoCode || content.level || content.Level || content.levelCode || content.LevelCode)
			const ids = []
			candidates.forEach(candidate => {
				const raw = String(candidate).trim()
				const skill = this.DSSkill.find(item => String(item.KyNang_MonHoc_ChiTietID) === raw || String(item.SkillID || '') === raw || String(item.MaKyNang || item.SkillCode || '') === raw || String(item.MucDoCode || '') === raw || this.normalizeSkillText(item.TenKyNang) === this.normalizeSkillText(raw))
				if (skill && !ids.some(id => String(id) === String(skill.KyNang_MonHoc_ChiTietID))) ids.push(skill.KyNang_MonHoc_ChiTietID)
			})
			return ids
		},
		normalizeHocLieuQuestions(questionList, hocLieuList) {
			return (questionList || []).flatMap(item => {
				const hocLieu = (hocLieuList || []).find(value => Number(value.HocLieuID) === Number(item.HocLieuID))
				// Giữ tên tài liệu gốc trước khi tách QUIZ_COMPOSITE thành nhiều câu để các câu con vẫn truy vết được nguồn.
				const sourceFileName = item.FileName || item.TenFile || item.TenNoiDung || hocLieu?.TenHocLieu || 'Học liệu nguồn'
				const base = { ...item, TenHocLieu: hocLieu?.TenHocLieu || '', Points: this.normalizeQuestionPoints(item.Points), _sourceFileName: sourceFileName, _selected: false, _supported: this.isSupportedImportType(item.LoaiNoiDung) }
				if (item.LoaiNoiDung !== 'QUIZ_COMPOSITE') return [{ ...base, _key: String(item.NoiDungID), _content: this.parseJson(item.DataJson, {}) }]
				const composite = this.parseJson(item.DataJson, {})
				const grouped = (composite.groups || []).flatMap(group => (group.questions || []).map(question => ({ question, groupTitle: group.title || '' })))
				return [...(composite.questions || []).map(question => ({ question, groupTitle: '' })), ...grouped].map(({ question, groupTitle }, index) => ({ ...base, _key: String(item.NoiDungID) + '_' + index, CompositeQuestionID: question.id || String(item.NoiDungID) + '_' + index, TenNoiDung: (item.TenNoiDung || 'Quiz') + (groupTitle ? ' — ' + groupTitle : '') + ' — Câu ' + (index + 1), LoaiNoiDung: question.type, Points: this.normalizeQuestionPoints(question.points), _content: question.content || {}, _supported: this.isSupportedImportType(question.type) }))
			})
		},
		isSupportedImportType(type) { return ['QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_TRUE_FALSE', 'QUIZ_MULTIPLE_TRUE_FALSE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_MATCHING', 'QUIZ_ORDERING'].includes(type) },
		buildImportedConfig(question) {
			const data = question._content || {}
			const type = question.LoaiNoiDung === 'QUIZ_TRUE_FALSE' ? 'QUIZ_MULTIPLE_TRUE_FALSE' : question.LoaiNoiDung
			const config = { questionText: data.prompt || '', isAdvanced: Boolean(data.isAdvanced), media: this.normalizeQuestionMedia(data.media) }
			if (type === 'QUIZ_SINGLE_CHOICE') { config.options = data.options || []; config.correctAnswer = data.correctAnswer }
			if (type === 'QUIZ_MULTIPLE_CHOICE') { config.options = data.options || []; config.correctAnswers = data.correctAnswers || [] }
			if (type === 'QUIZ_MULTIPLE_TRUE_FALSE') config.options = (data.options || []).map(option => ({ ...option, correctAnswer: option.correctAnswer ?? option.isTrue === true, inCorrectAnswer: option.inCorrectAnswer ?? option.isTrue === false }))
			if (type === 'QUIZ_FILL_IN_BLANK') config.parts = data.parts || []
			if (type === 'QUIZ_MATCHING') { config.columnA = data.columnA || []; config.columnB = data.columnB || []; config.correctPairs = data.correctPairs || [] }
			if (type === 'QUIZ_ORDERING') {
				config.items = Array.isArray(data.items) ? data.items : (Array.isArray(data.options) ? data.options : [])
				config.correctOrder = Array.isArray(data.correctOrder) && data.correctOrder.length ? data.correctOrder : config.items.map(item => item?.id)
				config.scoringMode = 'equal'
			}
			return { type, config }
		},
		buildImportedSkills(question) {
			// SkillsJson giữ khóa cũ KyNang_* và thêm mã chuẩn để Soạn bài tập nhận đúng taxonomy mức độ của môn.
			return (Array.isArray(question?._skillIds) ? question._skillIds : []).map(id => this.serializeQuestionSkill(id)).filter(Boolean)
		},
		serializeQuestionSkill(id) {
			const skill = this.DSSkill.find(item => String(item.KyNang_MonHoc_ChiTietID) === String(id))
			if (!skill) return null
			return {
				KyNang_MonHoc_ChiTietID: skill.KyNang_MonHoc_ChiTietID,
				TenKyNang: skill.TenKyNang || '',
				NhomKyNang: skill.NhomKyNang || '',
				SkillCode: skill.SkillCode || '',
				MucDoCode: skill.MucDoCode || '',
				id: skill.KyNang_MonHoc_ChiTietID,
				name: skill.TenKyNang || '',
			}
		},
		async saveImportedQuestions() {
			const selected = this.importQuestions.filter(item => item._selected && item._supported)
			if (!selected.length) return
			this.importSaving = true
			try {
				const previousGroup = this.selectedGroup
				const groupId = await this.ensureQuestionGroup()
				this.selectedGroup = previousGroup || { Id: groupId, Title: 'Chưa phân nhóm' }
				for (const [index, question] of selected.entries()) {
					const mapped = this.buildImportedConfig(question)
					const sourceFileName = question._sourceFileName || question.FileName || question.TenFile || question.TenHocLieu || 'Học liệu nguồn'
					const isFileOrJsonImport = this.importSourceType === 'DOCUMENT_FILE' || this.importSourceType === 'JSON_IMPORT' || !question.HocLieuID
					const sourceTracking = isFileOrJsonImport
						? { sourceType: this.importSourceType || 'DOCUMENT_FILE', sourceFileName }
						: { sourceType: 'HOC_LIEU_SO', sourceFileName, HocLieuID: question.HocLieuID, NoiDungID: question.NoiDungID, CompositeQuestionID: question.CompositeQuestionID || null }
					const sourceId = isFileOrJsonImport
						? (this.importSourceType || 'IMPORT') + '_' + Date.now() + '_' + index + '_' + Math.random().toString(36).slice(2)
						: 'HOC_LIEU_SO_' + (question.HocLieuID || 'HL') + '_' + (question.NoiDungID || 'ND') + '_' + (question.CompositeQuestionID || question.NoiDungID || (Date.now() + '_' + index))
					const payload = { GroupId: this.selectedGroup?.Id || null, SourceId: sourceId, Type: mapped.type, QuestionText: mapped.config.questionText || question.TenNoiDung || null, Points: this.normalizeQuestionPoints(question.Points), GradingType: this.getQuestionGradingType(mapped.type, question.GradingType || question.gradingType), IsAdvanced: mapped.config.isAdvanced ? 1 : 0, ConfigJson: JSON.stringify({ ...mapped.config, sourceTracking }), SkillsJson: JSON.stringify(this.buildImportedSkills(question)), RawJson: isFileOrJsonImport ? JSON.stringify(question._rawQuestion || question) : (question.DataJson || null), User: this.vueData.user?.UserID }
					const result = await fetchPromise('lms/EL_Question_Create', payload, { cache: false })
					if (!this.isApiSuccess(result)) throw new Error('import-failed')
				}
				this.selectedGroup = previousGroup
				this.dialogImport = false; this.importQuestions = []; this.importDefaultSkillIds = []; this.pendingQuestionLevelId = null
				await this.loadQuestions(); this.notify('Đã import ' + selected.length + ' câu hỏi vào ngân hàng.')
			} catch (error) { this.notify('Import chưa hoàn tất. Vui lòng kiểm tra lại danh sách câu hỏi.', 'error') }
			finally { this.importSaving = false }
		},
		parseJson(value, fallback) { if (value && typeof value === 'object') return value; try { return typeof value === 'string' && value.trim() ? JSON.parse(value) : fallback } catch (error) { return fallback } },
		isApiSuccess(result) {
			const data = Array.isArray(result?.data) ? result.data.flat(Infinity) : (Array.isArray(result) ? result.flat(Infinity) : [result])
			return data.some(item => item && (item.Id || item.Success === 1 || item.Success === true || item.Action === 'Inserted' || item.Action === 'Updated' || item.status === 'success'))
		},
		onQuestionSearchInput() {
		clearTimeout(this.questionSearchTimer)
		this.questionSearchTimer = setTimeout(() => this.loadQuestions(), 350)
		},
		async applyQuestionSearch() {
			clearTimeout(this.questionSearchTimer)
			this.questionSearchTimer = null
			await this.loadQuestions()
		},
		onClearSearch() {
			clearTimeout(this.questionSearchTimer)
			this.questionSearchTimer = null
			this.searchQ = ''
			this.loadQuestions()
		},
		notify(message, color = 'success') {
			this.snackbarRef?.value?.showSnackbar?.({ message, color })
		},
		getCurrentUserId() {
			const user = this.vueData?.user || {}
			return String(user.UserID ?? user.UserId ?? user.ID ?? user.Id ?? this.vueData?.UserID ?? '').trim()
		},
		getCurrentUserName() {
			const user = this.vueData?.user || {}
			return String(user.FullName || user.UserName || user.Name || user.DisplayName || '').trim()
		},
		getDocumentOwnerId(item) {
			const meta = this.getMeta(item)
			// Dữ liệu hiển thị đã được normalize thành createdByLabel; dùng fallback này để bản ghi cũ vẫn nhận đúng owner dù API không trả lại đúng tên cột audit.
			const candidates = [meta.ownerUserId, meta.OwnerUserID, meta.ownerId, item?.ownerUserId, item?.createdByLabel, item?.ownerLabel, item?.NguoiUploadID, item?.CreateUserID, item?.CreatedByID, item?.CreateByID, item?.CreatorID]
			return candidates.map(value => String(value ?? '').trim()).find(Boolean) || ''
		},
		getDocumentOwnerIdForDelete(item) {
			const meta = this.getMeta(item)
			// Xóa là thao tác phá dữ liệu nên chỉ dùng các trường định danh, không dùng tên hiển thị làm owner.
			// Nếu API không trả được owner ID thì trả rỗng để UI khóa xóa an toàn.
			const candidates = [meta.ownerUserId, meta.OwnerUserID, meta.ownerId, item?.ownerUserId, item?.NguoiUploadID, item?.CreateUserID, item?.CreatedByID, item?.CreateByID, item?.CreatorID, item?.CreateUser]
			return candidates.map(value => String(value ?? '').trim()).find(Boolean) || ''
		},
		isContentOwner(item) {
			const currentUserId = this.getCurrentUserId().toUpperCase()
			const ownerUserId = this.getDocumentOwnerIdForDelete(item).toUpperCase()
			return Boolean(currentUserId && ownerUserId && currentUserId === ownerUserId)
		},
		isInitiativeOwner(item) {
			if (this.activeBranch !== 'initiative') return true
			const currentUserId = this.getCurrentUserId().toUpperCase()
			const ownerUserId = this.getDocumentOwnerId(item).toUpperCase()
			return Boolean(currentUserId && ownerUserId && currentUserId === ownerUserId)
		},
		normalizeDocument(item) {
			let meta = {}
			try { meta = typeof item.DataJson === 'string' ? JSON.parse(item.DataJson || '{}') : (item.DataJson || {}) } catch (error) { meta = {} }
			const createdBy = item.NguoiUploadName || item.NguoiUpload || item.NguoiUploadID || item.CreateUser || item.CreatedBy || item.CreateBy || item.CreatorUser || item.CreatorID || item.TenNguoiTao || item.CreatedByName || item.NguoiTao || '—'
			const createdAt = item.CreateTime || item.CreatedAt || item.CreatedDate || '—'
			const updatedBy = item.NguoiCapNhatName || item.NguoiCapNhat || item.UpdateUserName || item.UpdateUser || item.UpdatedByName || item.UpdatedBy || '—'
			// CreateTime không phải UpdateTime: node mới tạo chỉ có audit tạo, nên để “—” nếu DB chưa ghi audit cập nhật.
			const rawUpdatedAt = item.UpdateTime || item.UpdatedAt || item.ModifiedTime || ''
			const hasUpdateAudit = updatedBy !== '—' && Boolean(rawUpdatedAt)
			const updatedAt = hasUpdateAudit ? rawUpdatedAt : '—'
			return {
				...item,
				displayName: item.TenNoiDung || item.FileName || item.TenFile || item.TenHocLieu || 'Tài liệu chưa có tên',
				// SP nguồn tài liệu trả ContentType theo PascalCase; chuẩn hóa về contentType để nhận diện đúng ảnh/PDF ngay cả khi tên file không có extension.
				contentType: meta.contentType || item.ContentType || item.contentType || item.LoaiNoiDung || 'Tài liệu',
				sourceLabel: item.NguonTaiNguyenCode || meta.origin || 'Học liệu',
				createdByLabel: createdBy,
				createdAtLabel: createdAt,
				updatedByLabel: updatedBy,
				updatedLabel: updatedAt,
				// Giữ ownerLabel để autocomplete media cũ vẫn hiển thị tương thích với dữ liệu đã chuẩn hóa.
				ownerLabel: createdBy,
				// Không dùng tên hiển thị làm owner cho thao tác xóa; thiếu ID thì khóa xóa an toàn.
				ownerUserId: this.getDocumentOwnerIdForDelete({ ...item, DataJson: meta }),
				fileUrl: item.FileURL || item.FileUrl || item.Url || item.URL || item.Link || item.DetailUrl || meta.url || meta.FILE_URL || '',
				_meta: meta,
			}
		},
		// Cờ interactive và interactions được lưu trong DataJson khi tạo video; đọc qua hàm này để bản ghi cũ vẫn hiển thị như video thường.
		isInteractiveVideo(item) {
			return this.getMeta(item)?.interactive === true
		},
		getInteractiveQuestionCount(item) {
			const meta = this.getMeta(item)
			return this.normalizeInteractiveTimerMarkers(meta.timerMarkers || meta.interactions || []).reduce((count, marker) => count + marker.questions.length, 0)
		},
		// Hàm format hiển thị ngày giờ cập nhật từ chuỗi ISO DB (YYYY-MM-DDTHH:mm:ss) sang DD/MM/YYYY HH:mm
		formatDate(value) {
			if (!value || value === '—') return '—'
			const date = new Date(value)
			if (isNaN(date.getTime())) return value
			const pad = num => String(num).padStart(2, '0')
			const d = pad(date.getDate())
			const m = pad(date.getMonth() + 1)
			const y = date.getFullYear()
			const h = pad(date.getHours())
			const min = pad(date.getMinutes())
			return `${d}/${m}/${y} ${h}:${min}`
		},
		getTypeLabel(type) {
			const labels = {
				QUIZ_SINGLE_CHOICE: 'Trắc nghiệm 1 đáp án',
				QUIZ_MULTIPLE_CHOICE: 'Trắc nghiệm nhiều đáp án',
				QUIZ_TRUE_FALSE: 'Đúng / Sai',
				QUIZ_MULTIPLE_TRUE_FALSE: 'Nhiều mệnh đề Đúng / Sai',
				QUIZ_FILL_IN_BLANK: 'Điền chỗ trống',
				QUIZ_SHORT_ANSWER: 'Trả lời ngắn',
				QUIZ_ESSAY: 'Tự luận',
				SHORT_ANSWER: 'Trả lời ngắn',
				ESSAY: 'Tự luận',
				QUIZ_MATCHING: 'Nối đáp án',
				QUIZ_ORDERING: 'Sắp xếp thứ tự',
			}
			return labels[type] || type || 'Chưa phân loại'
		},
		// Nhận diện icon đại diện chi tiết cho từng loại tệp tin
		getFileIcon(item) {
			if (this.isInteractiveVideo(item)) return 'mdi-timeline-text-outline'
			const value = String(item?.contentType || item?.LoaiNoiDung || item?.displayName || item?.FileName || item?.fileUrl || '').toLowerCase()
			if (/\.pdf\b|application\/pdf/.test(value)) return 'mdi-file-pdf-box'
			if (/\.(docx?|doc)\b|msword|wordprocessingml/.test(value)) return 'mdi-file-word-box'
			if (/\.(xlsx?|xls|csv)\b|ms-excel|spreadsheetml/.test(value)) return 'mdi-file-excel-box'
			if (/\.(pptx?|ppt)\b|ms-powerpoint|presentationml/.test(value)) return 'mdi-file-powerpoint-box'
			if (/ispring/.test(value)) return 'mdi-play-box-multiple'
			if (/\.html?\b|text\/html/.test(value)) return 'mdi-language-html5'
			if (/video|youtube|\.(mp4|webm|mov|mkv|avi)\b/.test(value)) return 'mdi-play-circle-outline'
			if (/audio|\.(mp3|wav|aac|m4a|ogg)\b/.test(value)) return 'mdi-volume-high'
			if (/image|\.(png|jpe?g|gif|webp|svg|bmp)\b/.test(value)) return 'mdi-image-outline'
			return 'mdi-file-document-outline'
		},
		// Màu sắc đặc trưng nhận diện nhanh định dạng tệp
		getFileColor(item) {
			if (this.isInteractiveVideo(item)) return 'deep-purple'
			const value = String(item?.contentType || item?.LoaiNoiDung || item?.displayName || item?.FileName || item?.fileUrl || '').toLowerCase()
			if (/\.pdf\b|application\/pdf/.test(value)) return 'red-darken-1'
			if (/\.(docx?|doc)\b|msword|wordprocessingml/.test(value)) return 'blue-darken-2'
			if (/\.(xlsx?|xls|csv)\b|ms-excel|spreadsheetml/.test(value)) return 'green-darken-2'
			if (/\.(pptx?|ppt)\b|ms-powerpoint|presentationml/.test(value)) return 'deep-orange-darken-1'
			if (/ispring/.test(value)) return 'purple'
			if (/\.html?\b|text\/html/.test(value)) return 'amber-darken-2'
			if (/video|youtube|\.(mp4|webm|mov|mkv|avi)\b/.test(value)) return 'deep-purple'
			if (/audio|\.(mp3|wav|aac|m4a|ogg)\b/.test(value)) return 'teal'
			if (/image|\.(png|jpe?g|gif|webp|svg|bmp)\b/.test(value)) return 'orange-darken-1'
			return 'primary'
		},
		// Định dạng dung lượng tệp tin (KB, MB)
		formatFileSize(bytes) {
			const size = Number(bytes || 0)
			if (!size || isNaN(size)) return ''
			if (size < 1024) return size + ' B'
			if (size < 1024 * 1024) return (size / 1024).toFixed(1) + ' KB'
			return (size / (1024 * 1024)).toFixed(1) + ' MB'
		},
		// Định dạng ngày giờ ngắn gọn (DD/MM/YYYY)
		formatDateShort(value) {
			if (!value || value === '—') return ''
			const date = new Date(value)
			if (isNaN(date.getTime())) return String(value).slice(0, 10)
			const pad = num => String(num).padStart(2, '0')
			return `${pad(date.getDate())}/${pad(date.getMonth() + 1)}/${date.getFullYear()}`
		},
		// Nhãn loại tệp tin ngắn gọn, dễ hiểu cho người dùng
		getFileTypeLabel(item) {
			if (this.isInteractiveVideo(item)) return 'Video tương tác'
			const value = String(item?.contentType || item?.LoaiNoiDung || item?.displayName || item?.FileName || item?.fileUrl || '').toLowerCase()
			if (/\.pdf\b|application\/pdf/.test(value)) return 'PDF'
			if (/\.(docx?|doc)\b|msword|wordprocessingml/.test(value)) return 'Word'
			if (/\.(xlsx?|xls|csv)\b|ms-excel|spreadsheetml/.test(value)) return 'Excel'
			if (/\.(pptx?|ppt)\b|ms-powerpoint|presentationml/.test(value)) return 'PowerPoint'
			if (/ispring/.test(value)) return 'iSpring'
			if (/\.html?\b|text\/html/.test(value)) return 'HTML'
			if (/video|youtube|\.(mp4|webm|mov|mkv|avi)\b/.test(value)) return 'Video'
			if (/audio|\.(mp3|wav|aac|m4a|ogg)\b/.test(value)) return 'Audio'
			if (/image|\.(png|jpe?g|gif|webp|svg|bmp)\b/.test(value)) return 'Hình ảnh'
			return item?.contentType || item?.LoaiNoiDung || 'Tài liệu'
		},
		getMeta(item) {
			if (item?._meta) return item._meta
			try { return typeof item?.DataJson === 'string' ? JSON.parse(item.DataJson || '{}') : (item?.DataJson || {}) } catch (error) { return {} }
		},
		getFileUrl(item) {
			const meta = this.getMeta(item)
			// Các bản iSpring cũ chỉ lưu iSpringURL; fallback này giữ khả năng mở tài liệu đã tạo trước khi chuẩn hóa metadata.url.
			const rawUrl = item.fileUrl || item.FileURL || item.FileUrl || item.Url || item.URL || item.Link || item.DetailUrl || meta.url || meta.iSpringURL || meta.FILE_URL || ''
			if (!rawUrl) return ''

			// Nếu đã là link URL tuyệt đối (http/https)
			if (/^https?:\/\//i.test(rawUrl)) return rawUrl
			if (/^\/\//.test(rawUrl)) return 'https:' + rawUrl

			// Ghép vueData.v_Set.urlReadFile + url của db
			const base = String(this.vueData?.v_Set?.urlReadFile || this.vueData?.v_Set?.urlReturnFile || 'https://file.lhbs.vn/lms/').replace(/\/$/, '')
			const cleanPath = String(rawUrl).replace(/^\//, '')
			return `${base}/${cleanPath}`
		},
		getLmsStorageFileId(item, rawFileDataUrl = '') {
			const meta = this.getMeta(item)
			const driveFileId = String(meta.driveFileId || meta.DriveFileId || '').trim()
			const dataUrlFileId = String(rawFileDataUrl).match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
			const candidates = [meta.fileId, meta.FILE_ID, item?.FileID, item?.fileId, dataUrlFileId]
			// Một số bản ghi cũ đã ghi nhầm Drive ID vào dbUrl/fileId. ID đó không được dùng với endpoint LMS FileData.
			return candidates.map(value => String(value || '').trim()).find(value => value && value !== driveFileId) || ''
		},
		getLmsFileUrl(item) {
			const meta = this.getMeta(item)
			const rawFileDataUrl = String(meta.dbUrl || meta.DB_URL || meta.FILE_URL || meta.url || item?.FileURL || item?.FileUrl || '').trim()
			const fileId = this.getLmsStorageFileId(item, rawFileDataUrl)
			const driveFileId = String(meta.driveFileId || meta.DriveFileId || '').trim()
			const rawFileDataId = String(rawFileDataUrl).match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
			const isRawLmsFileData = /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/FileData\//i.test(rawFileDataUrl) || /(?:^|\/)FileData\//i.test(rawFileDataUrl)
			const hasExplicitLmsStorage = /LMS_(?:DB_)?FILEDATA/i.test(String(meta.storage || ''))
			// FP_TaiNguyen_SourceFile_GetAll gộp OriginalFileID (Google Drive) và LmsFileID vào cột FileID.
			// Nếu FileURL là link ngoài, tuyệt đối không dùng FileID đó để dựng nhầm endpoint LMS.
			if (rawFileDataUrl && !isRawLmsFileData && !hasExplicitLmsStorage) return ''
			const canUseRawFileDataUrl = isRawLmsFileData && rawFileDataId !== driveFileId
			const fileDataUrl = canUseRawFileDataUrl ? rawFileDataUrl : (fileId ? `/FileData/${fileId}` : '')
			if (!fileDataUrl) return ''
			if (/^https?:\/\//i.test(fileDataUrl)) return fileDataUrl
			const base = String(this.vueData?.v_Set?.urlReadFile || '').replace(/\/$/, '')
			return base ? `${base}/${String(fileDataUrl).replace(/^\//, '')}` : this.getFileUrl({ ...item, fileUrl: fileDataUrl })
		},
		// Xử lý mở tài liệu trong module lms-content-hub:
		// 1. Tài liệu HTML (lưu nội dung text trong DataJson hoặc có link file): Xem trực tiếp qua preview dialog.
		// 2. File PDF: Nhúng qua viewer nội bộ của LMS.
		// 3. File Office (DOCX, XLSX, PPTX, PPT, DOC, XLS): Nhúng qua viewer nội bộ của LMS.
		// 4. Link Google Docs/Presentation: Nhúng hoặc mở trực tiếp.
		// 5. Các định dạng khác: Mở tab mới.
		// Ưu tiên sử dụng iframeRef của LMS (nếu có) để có đầy đủ toolbar, fullscreen, reload và đóng; fallback về previewDialog của page.
		openFile(item) {
			if (this.activeBranch === 'initiative' && !this.isInitiativeOwner(item) && !this.isInitiativeInspectionMode) return this.notify('Chỉ người tải lên mới được xem file này.', 'warning')
			const meta = this.getMeta(item)
			// File Sáng kiến vẫn lấy từ LMS_FileData, nhưng endpoint trả attachment nên các định dạng xem được phải qua viewer.
			if (this.activeBranch === 'initiative') {
				const lmsFileUrl = this.getLmsFileUrl(item)
				if (!lmsFileUrl) return this.notify('File Sáng kiến chưa có đường dẫn LMS_FileData.', 'warning')
				// Dùng URL LMS làm nguồn dữ liệu; Office/PDF/HTML phải mở qua viewer để tránh trình duyệt tải file trực tiếp.
				if (this.isHtmlDoc(item) || meta.htmlContent) return this.openHtmlPreview(item, lmsFileUrl)
				if (this.isImage(item)) return this.openImagePreview(item, lmsFileUrl)
				if (this.isPdf(item)) return this.openPdfPreview(item, lmsFileUrl)
				if (this.isOfficeDoc(item)) return this.openOfficePreview(item, lmsFileUrl)
				return window.open(lmsFileUrl, '_blank', 'noopener,noreferrer')
			}
			const url = this.getFileUrl(item)

			// Nếu tài liệu là HTML lưu nội dung text trực tiếp trong DataJson
			if (this.isHtmlDoc(item) || meta.htmlContent) {
				return this.openHtmlPreview(item, url)
			}

			if (!url) return this.notify('Tài liệu chưa có đường dẫn mở.', 'warning')
			if (this.isImage(item)) return this.openImagePreview(item, this.getImagePreviewUrl(item, url))
			if (this.isPdf(item)) return this.openPdfPreview(item, url)
			if (this.isOfficeDoc(item)) return this.openOfficePreview(item, url)
			if (this.isGoogleDocs(item)) return this.openGooglePreview(item, url)
			window.open(url, '_blank', 'noopener,noreferrer')
		},
		showViewer(title, previewUrl, sourceUrl, icon = 'mdi-file-document-outline', htmlContent = '', options = {}) {
			this.previewHtmlContent = htmlContent || ''
			this.previewImageUrl = ''
			this.previewCropTop = Number(options.cropTop) || 0
			if (this.iframeRef?.value?.openWindow && previewUrl) {
				this.iframeRef.value.openWindow({
					title: title || 'Xem tài liệu',
					url: previewUrl,
					icon,
					cropTop: this.previewCropTop
				})
			} else {
				this.previewTitle = title || 'Xem tài liệu'
					this.previewUrl = previewUrl
				this.previewDialog = true
			}
		},
		// Ảnh được mở ngay trong dialog của Content Hub để không phụ thuộc khả năng render iframe của Google Drive.
		openImagePreview(item, sourceUrl) {
			const previewUrl = sourceUrl || this.getImagePreviewUrl(item)
			if (!previewUrl) return this.notify('Hình ảnh chưa có đường dẫn để xem.', 'warning')
			this.previewTitle = item?.displayName || item?.TenNoiDung || 'Xem hình ảnh'
			this.previewUrl = ''
			this.previewHtmlContent = ''
			this.previewImageUrl = previewUrl
			this.previewCropTop = 0
			this.previewDialog = true
		},
		// Ưu tiên bản binary LMS; chỉ fallback sang ảnh Drive dạng thumbnail cho dữ liệu cũ không còn fileId LMS.
		getImagePreviewUrl(item, fallbackUrl = '') {
			const lmsUrl = this.getLmsFileUrl(item)
			if (lmsUrl) return lmsUrl
			const meta = this.getMeta(item)
			const driveFileId = meta.driveFileId || meta.DriveFileId || this.getGoogleDriveFileId(String(fallbackUrl || this.getFileUrl(item) || ''))
			if (driveFileId) return `https://drive.google.com/thumbnail?id=${encodeURIComponent(driveFileId)}&sz=w2000`
			return fallbackUrl || this.getFileUrl(item)
		},
		// Kiểm tra định dạng PDF
		isPdf(item) {
			const value = `${item?.displayName || ''} ${item?.FileName || ''} ${item?.contentType || ''} ${this.getFileUrl(item)}`.toLowerCase()
			return /\.pdf\b|application\/pdf/.test(value)
		},
		isImage(item) {
			const meta = this.getMeta(item)
			const value = `${item?.displayName || ''} ${item?.FileName || ''} ${item?.TenNoiDung || ''} ${item?.LoaiNoiDung || ''} ${item?.contentType || ''} ${meta.fileName || ''} ${meta.contentType || ''} ${meta.mediaType || ''} ${this.getFileUrl(item)}`.toLowerCase()
			return /image\/(?:png|jpe?g|gif|webp|svg\+xml|bmp)|\bimage\b|\.(?:png|jpe?g|gif|webp|svg|bmp)(?:[?#].*)?/.test(value)
		},
		// Nhúng trực tiếp file PDF vào LMS
		openPdfPreview(item, sourceUrl) {
			const title = item.displayName || 'Xem tài liệu PDF'
			const lmsViewerUrl = this.getLmsFileViewerUrl(item, sourceUrl)
			if (lmsViewerUrl) {
				// Chỉ PDF lưu trong LMS dùng viewer nội bộ; ảnh và các nguồn ngoài vẫn theo flow cũ.
				return this.showViewer(title, lmsViewerUrl, sourceUrl, 'mdi-file-pdf-box')
			}
			// Chỉ khi nào file nguồn thật sự là Google Drive (drive.google.com) và không phải file trên LMS thì mới fallback preview Google Drive
			const isRealGoogleDrive = /drive\.google\.com/i.test(sourceUrl)
			const driveFileId = isRealGoogleDrive ? this.getGoogleDriveFileId(sourceUrl) : ''
			const previewUrl = driveFileId ? `https://drive.google.com/file/d/${driveFileId}/preview` : sourceUrl
			this.showViewer(title, previewUrl, sourceUrl, 'mdi-file-pdf-box')
		},
		// Kiểm tra định dạng tài liệu Office
		isOfficeDoc(item) {
			const value = `${item?.displayName || ''} ${item?.FileName || ''} ${item?.contentType || ''} ${this.getFileUrl(item)}`.toLowerCase()
			return /\.(docx?|xlsx?|pptx?)\b|application\/(msword|vnd\.openxmlformats-officedocument|vnd\.ms-excel|vnd\.ms-powerpoint)/.test(value)
		},
		// Gọi viewer phù hợp: file LMS dùng viewer nội bộ; link Drive ngoài dùng preview Drive trực tiếp.
		getLmsFileViewerUrl(item, sourceUrl = '') {
			const meta = this.getMeta(item)
			const source = String(sourceUrl || '')
			const rawFileDataUrl = String(meta.dbUrl || meta.DB_URL || meta.FILE_URL || item?.FileURL || item?.FileUrl || source || '')
			const isLmsFileData = /(?:file\.lhbs\.vn|lms\.lhbs\.vn)\/lms\/FileData\//i.test(rawFileDataUrl) || /(?:^|\/)FileData\//i.test(rawFileDataUrl)
			if (!isLmsFileData) return ''
			const sourceId = rawFileDataUrl.match(/\/FileData\/([^/?#]+)/i)?.[1] || ''
			const fileId = this.getLmsStorageFileId(item, rawFileDataUrl) || (sourceId && sourceId !== String(meta.driveFileId || meta.DriveFileId || '').trim() ? sourceId : '')
			const rawFileName = item?.displayName || item?.FileName || item?.TenFile || meta.fileName || meta.FILE_NAME || ''
			if (!fileId || !rawFileName) return ''
			// Chuẩn hóa tên file: loại bỏ các ký tự đặc biệt gây lỗi IIS Request Filtering (404 Not Found) như &, +, #, %, ?, :, /, \, *, ", <, >, |
			// nhưng vẫn giữ nguyên extension và hỗ trợ tiếng Việt có dấu.
			const lastDotIndex = rawFileName.lastIndexOf('.')
			const baseName = lastDotIndex !== -1 ? rawFileName.substring(0, lastDotIndex) : rawFileName
			const ext = lastDotIndex !== -1 ? rawFileName.substring(lastDotIndex) : ''
			const cleanBase = baseName.replace(/[&+%#?:/\\*"<>|]/g, '_').trim() || 'file'
			const fileName = `${cleanBase}${ext}`
			// Viewer LMS cần tên file ở path; encode từng phần để giữ đúng tên có dấu/khoảng trắng.
			return `https://file.lhbs.vn/lms/viewer/FileData/${encodeURIComponent(fileId)}/${encodeURIComponent(fileName)}`
		},
		openOfficePreview(item, sourceUrl) {
			const title = item.displayName || 'Xem tài liệu Office'
			const lmsSourceUrl = this.getLmsFileUrl(item)
			const lmsViewerUrl = this.getLmsFileViewerUrl(item, lmsSourceUrl)
			if (lmsViewerUrl) {
				// Chỉ dùng viewer nội bộ khi đã xác định đúng FILE_ID thuộc LMS FileData.
				return this.showViewer(title, lmsViewerUrl, lmsSourceUrl, 'mdi-file-document-edit-outline')
			}

			const driveFileId = this.getGoogleDriveFileId(sourceUrl)
			if (driveFileId) {
				// Link Drive bên ngoài đã có viewer riêng; dùng /preview để tránh Office Viewer không đọc được redirect /uc?export=download.
				const previewUrl = `https://drive.google.com/file/d/${encodeURIComponent(driveFileId)}/preview`
				return this.showViewer(title, previewUrl, sourceUrl, 'mdi-file-document-edit-outline', '', { cropTop: 90 })
			}
			const previewUrl = `https://view.officeapps.live.com/op/view.aspx?src=${encodeURIComponent(sourceUrl)}`
			this.showViewer(title, previewUrl, sourceUrl, 'mdi-file-document-edit-outline', '', { cropTop: 90 })
		},
		// Nhận diện tài liệu Google Docs/Slides nếu có sẵn link
		isGoogleDocs(item) {
			return /docs\.google\.com\/(presentation|document|spreadsheets)\/d\/[^/?#]+/i.test(this.getFileUrl(item))
		},
		// Nhúng trực tiếp tài liệu Google Docs/Slides đã có sẵn
		openGooglePreview(item, sourceUrl) {
			const title = item.displayName || 'Xem tài liệu'
			const slideMatch = sourceUrl.match(/docs\.google\.com\/presentation\/d\/([^/?#]+)/i)
			const previewUrl = slideMatch
				? `https://docs.google.com/presentation/d/${slideMatch[1]}/embed?start=false&loop=false&delayms=3000`
				: sourceUrl
			this.showViewer(title, previewUrl, sourceUrl, 'mdi-presentation-play')
		},
		getGoogleDriveFileId(url) {
			const pathMatch = url.match(/drive\.google\.com\/file\/d\/([^/?#]+)/i)
			if (pathMatch) return pathMatch[1]
			try {
				const parsed = new URL(url)
				return /drive\.google\.com$/i.test(parsed.hostname) ? parsed.searchParams.get('id') : ''
			} catch (error) { return '' }
		},
		// Nhận diện tài liệu định dạng HTML
		isHtmlDoc(item) {
			const value = `${item?.displayName || ''} ${item?.FileName || ''} ${item?.TenNoiDung || ''} ${item?.LoaiNoiDung || ''} ${item?.contentType || ''}`.toLowerCase()
			return /\.html?\b|text\/html|\bhtml\b/.test(value)
		},
		// Mở xem trước tài liệu HTML: ưu tiên render chuỗi HTML lưu trong DataJson, fallback link URL
		openHtmlPreview(item, sourceUrl) {
			const meta = this.getMeta(item)
			const title = item.displayName || item.TenNoiDung || 'Xem tài liệu HTML'
			const htmlContent = meta.htmlContent || ''
			if (htmlContent) {
				this.showViewer(title, '', '', 'mdi-code-tags', htmlContent)
			} else if (sourceUrl) {
				this.showViewer(title, sourceUrl, sourceUrl, 'mdi-code-tags')
			} else {
				this.notify('Nội dung HTML trống hoặc chưa có dữ liệu.', 'warning')
			}
		}
	}
	}
</script>

<style scoped>
/* Hiệu ứng chớp nháy màu xanh sáng trên toàn bộ các ô của dòng vừa lưu trong 2.5s rồi tự động trở về màu gốc */
:deep(tr.question-row-highlighted),
:deep(tr.question-row-highlighted > td) {
	animation: questionHighlightFlash 2.5s ease-out forwards !important;
}
@keyframes questionHighlightFlash {
	0% {
		background-color: #c8e6c9 !important; /* Xanh lá sáng rõ */
	}
	40% {
		background-color: #e8f5e9 !important; /* Xanh nhạt */
	}
	100% {
		background-color: transparent !important; /* Trở về 100% màu gốc của bảng */
	}
}
/* BẮT BUỘC: Đổi màu dòng table câu hỏi chưa có đáp án đúng để giáo viên nhận diện cần thêm đáp án */
:deep(tr.question-row-no-answer),
:deep(tr.question-row-no-answer > td) {
	background-color: #fffbeb !important; /* Màu vàng cam nhạt amber-50 cảnh báo */
}
:deep(tr.question-row-no-answer:hover),
:deep(tr.question-row-no-answer:hover > td) {
	background-color: #fef3c7 !important; /* Đậm hơn một chút khi hover */
}
:deep(tr.question-row-no-answer > td:first-child) {
	border-left: 3px solid #f59e0b !important; /* Vạch viền cam đậm ở mép trái */
}
.question-no-answer-warning {
	padding: 3px 8px;
	border-radius: 4px;
	background-color: #fef3c7;
	border: 1px dashed #f59e0b;
	width: fit-content;
}
.content-hub-layout { height: calc(100dvh - 53px); overflow: hidden; }
/* Menu chọn nhánh cố định; chỉ vùng danh sách bên dưới được cuộn để không làm mất Hồ sơ/Sáng kiến/Khối môn. */
.content-hub-sidebar { display: flex; flex-direction: column; height: 100%; min-height: 0; overflow: hidden; border-right: 1px solid rgba(0, 0, 0, .12); background: rgba(0, 0, 0, .02); }
.content-hub-sidebar-menu { flex: 0 0 auto; }
.content-hub-branch-section { flex: 1 1 auto; min-height: 0; overflow-x: hidden; overflow-y: auto; }
.content-hub-main { height: 100%; overflow: hidden; }
.content-hub-documents { height: calc(100% - 105px); overflow: hidden; }
.content-hub-documents .profile-drive-toolbar { min-height: 42px; }
.content-hub-documents .profile-drive-toolbar .v-breadcrumbs-item:not(.v-breadcrumbs-item--disabled) { cursor: pointer; }
.content-hub-documents .profile-folder-grid { display: grid; grid-template-columns: repeat(auto-fill, minmax(min(100%, 280px), 1fr)); gap: 8px; }
.content-hub-documents .profile-folder-tree { max-height: 260px; overflow-y: auto; }
.content-hub-documents .profile-tree-title { cursor: pointer; border-radius: 4px; padding: 2px 6px; transition: background-color .15s ease, color .15s ease; }
/* Màu active tự quản lý vì slot title chặn click của v-treeview khi mở folder. */
.content-hub-documents .profile-tree-title--active { background: rgba(var(--v-theme-primary), .14); color: rgb(var(--v-theme-primary)); font-weight: 700; }
.content-hub-documents .profile-tree-count-badge { font-size: 11px; font-weight: 600; line-height: 1; padding: 2px 5px; border-radius: 10px; background: rgba(var(--v-theme-primary), .12); color: rgb(var(--v-theme-primary)); margin-left: 4px; }
.content-hub-documents .profile-tree-empty-badge { font-size: 11px; font-weight: 500; line-height: 1; padding: 2px 5px; border-radius: 10px; background: rgba(0, 0, 0, .06); color: rgba(0, 0, 0, .45); margin-left: 4px; }
/* Card chiếm trọn track auto-fill để không sinh khoảng trắng thừa bên trong mỗi cột. */
.content-hub-documents .profile-folder-card { width: 100%; cursor: pointer; transition: background-color .15s ease, box-shadow .15s ease; }
.content-hub-documents .profile-folder-card:hover { background: rgba(var(--v-theme-primary), .10); box-shadow: 0 2px 8px rgba(0, 0, 0, .08); }
.content-hub-documents .profile-folder-info { flex: 1 1 auto; min-width: 0; }
.content-hub-documents .profile-folder-name { min-width: 0; overflow-wrap: anywhere; white-space: normal; line-height: 1.35; }
.content-hub-questions { height: calc(100% - 105px); min-height: 0; overflow: hidden; padding: 12px; box-sizing: border-box; }
.content-hub-question-row { height: 100%; min-height: 0; align-items: stretch; }
.content-hub-group-panel { min-height: 320px; padding: 0; border-right: 1px solid rgba(0, 0, 0, .12); }
.content-hub-question-panel { min-height: 320px; padding: 0; }
.content-hub-question-panel { display: flex; flex-direction: column; height: 100%; min-height: 0; overflow: hidden; }
.question-group-content { padding-right: 12px; }
.question-group-toolbar { min-height: 36px; }
.question-group-list .v-list-item { min-height: 48px; padding-inline: 10px; }
.question-group-list .v-list-item-title,
.question-group-list .v-list-item-subtitle { min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.question-list-content { display: flex; flex-direction: column; height: 100%; min-height: 0; overflow: hidden; padding-left: 12px; }
.content-hub-empty-state { min-height: 240px; display: flex; flex-direction: column; align-items: center; justify-content: center; text-align: center; padding: 32px 16px; color: rgba(0, 0, 0, .54); }
.question-empty-state { min-height: 300px; }
.content-hub-question-table {
	width: 100% !important;
}
.content-hub-question-table :deep(.v-table__wrapper),
.content-hub-question-table :deep(table) {
	width: 100% !important;
	min-width: 100% !important;
}
.question-search-field { max-width: 220px; min-width: 120px; }
.upload-content-panel {
	border: 1px solid rgba(var(--v-theme-primary), .22);
	border-radius: 10px;
	overflow: hidden;
	background: #fbfdfc;
}
.content-hub-interactive-video .content-hub-interactive-player { height: 420px; overflow: hidden; border-radius: 8px; background: #000; }
.content-hub-interactive-video .content-hub-youtube-clean-shield { position: absolute; inset: 0; z-index: 3; background: transparent; cursor: default; }
.content-hub-interactive-video .content-hub-interactive-timeline { position: relative; min-height: 22px; padding: 0 4px; cursor: pointer; }
.content-hub-interactive-video .content-hub-interactive-marker { position: absolute; top: 5px; width: 12px; height: 12px; margin-left: -6px; border: 2px solid #fff; border-radius: 50%; background: rgb(var(--v-theme-warning)); box-shadow: 0 1px 4px rgba(0, 0, 0, .35); cursor: ew-resize; z-index: 2; }
.content-hub-interactive-video .content-hub-interactive-marker:hover { transform: scale(1.2); }
.content-hub-interactive-video .content-hub-interactive-marker-count { position: absolute; top: -8px; left: 8px; min-width: 18px; height: 18px; padding: 0 4px; border-radius: 9px; background: rgb(var(--v-theme-primary)); color: #fff; font-size: 10px; line-height: 18px; text-align: center; font-weight: 700; }
.content-hub-interactive-video .content-hub-interactive-marker-group { padding: 10px; border: 1px solid rgba(var(--v-theme-primary), .18); border-radius: 8px; background: rgba(var(--v-theme-primary), .025); }
.content-hub-interactive-video .content-hub-interactive-question-row { padding: 8px 10px; border-left: 3px solid rgba(var(--v-theme-primary), .35); border-radius: 4px; background: #fff; }
.content-hub-interactive-video .content-hub-interactive-response-limit { display: flex; align-items: center; margin-top: 4px; color: rgba(0, 0, 0, .55); font-size: 12px; line-height: 1.35; }
.content-hub-interactive-video .content-hub-interactive-time { flex: 0 0 110px; }
.upload-content-header {
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 12px;
	padding: 12px 14px;
	background: rgba(var(--v-theme-primary), .055);
}
.upload-content-heading {
	display: flex;
	align-items: center;
	gap: 10px;
	min-width: 0;
}
.upload-content-icon {
	display: flex;
	align-items: center;
	justify-content: center;
	flex: 0 0 34px;
	width: 34px;
	height: 34px;
	border-radius: 8px;
	background: rgba(var(--v-theme-primary), .12);
}
.upload-content-body { padding: 14px; }
.upload-content-section { display: flex; flex-direction: column; gap: 8px; }
.upload-section-label {
	display: flex;
	align-items: center;
	gap: 6px;
	color: rgba(0, 0, 0, .68);
	font-size: 13px;
	font-weight: 600;
}
.upload-section-divider {
	display: flex;
	align-items: center;
	gap: 10px;
	margin: 2px 0;
	color: rgba(0, 0, 0, .45);
	font-size: 12px;
}
.upload-section-divider::before,
.upload-section-divider::after {
	content: '';
	height: 1px;
	flex: 1 1 auto;
	background: rgba(0, 0, 0, .12);
}
.upload-info-banner {
	display: flex;
	align-items: flex-start;
	gap: 8px;
	padding: 9px 10px;
	border-radius: 6px;
	background: rgba(var(--v-theme-primary), .06);
	color: rgba(0, 0, 0, .62);
	font-size: 12px;
	line-height: 1.45;
}
.upload-type-option { cursor: pointer; transition: border-color .15s ease, background-color .15s ease; }
.upload-type-option:hover { border-color: rgb(var(--v-theme-primary)); background: rgba(var(--v-theme-primary), .04); }
.upload-type-option--active { border-color: rgb(var(--v-theme-primary)) !important; border-width: 1.5px !important; background-color: rgba(var(--v-theme-primary), .12) !important; }
.upload-slide-tabs { min-height: 42px; }
.upload-slide-window { overflow: visible; }
.upload-slide-panel { padding: 6px 1px 1px; }
.ispring-upload-zone { border: 1px dashed rgba(var(--v-theme-primary), .6); border-radius: 6px; padding: 18px 16px; text-align: center; cursor: pointer; background: rgba(var(--v-theme-primary), .03); transition: background-color .15s ease, border-color .15s ease; }
.ispring-upload-zone:hover { border-color: rgb(var(--v-theme-primary)); background: rgba(var(--v-theme-primary), .08); }
.content-hub-question-panel .question-list-title { white-space: normal; line-height: 1.45; }
.content-hub-question-panel .question-list-subtitle { white-space: normal; opacity: 1; }
.content-hub-question-panel .question-meta-row { display: flex; align-items: center; flex-wrap: wrap; gap: 0 6px; min-height: 20px; line-height: 1.35; }
.content-hub-question-panel .question-meta-type { font-weight: 500; }
.content-hub-question-panel .question-meta-separator { color: rgba(0, 0, 0, .42); }
.content-hub-question-panel .question-media-badge { display: inline-flex; align-items: center; gap: 3px; margin-left: 4px; color: rgb(var(--v-theme-primary)); }
.content-hub-question-panel .question-answer-preview { border-left: 3px solid rgba(var(--v-theme-success), .45); padding-left: 10px; }
.content-hub-question-panel .question-answer-row { display: block; margin-bottom: 8px; }
.content-hub-question-panel .question-answer-label { display: block; margin-bottom: 2px; color: rgb(var(--v-theme-success)); font-weight: 600; white-space: normal; }
.content-hub-question-panel .question-answer-value { display: block; width: 100%; min-width: 0; overflow-wrap: anywhere; word-break: break-word; }
.content-hub-question-panel .question-answer-value :deep(.uc-latex-view) { display: block; width: 100%; min-width: 0; max-width: 100%; white-space: normal; overflow-wrap: anywhere; word-break: break-word; }
.content-hub-question-panel .question-source-file { display: flex; align-items: center; min-width: 0; max-width: 160px; color: rgba(0, 0, 0, .62); font-size: 12px; line-height: 1.35; }
.content-hub-question-panel .question-source-file span { display: block; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.content-hub-question-panel .question-type-chip { align-self: flex-start; width: fit-content; max-width: 100%; }
.content-hub-question-panel .question-list-title { line-height: 1.55; }
.content-hub-question-panel .question-answer-row { line-height: 1.5; margin-bottom: 4px; }
.content-hub-media-panel .v-expansion-panel-text__wrapper { padding: 0 8px 12px; }

/* Giữ câu hỏi và đáp án thành một luồng đọc liên tục; media là phần bổ trợ nên hiển thị sau đáp án. */
.content-hub-question-dialog { display: flex; flex-direction: column; }
.content-hub-question-dialog :deep(.question-answer-section) { order: 1; }
.content-hub-question-dialog :deep(.question-media-section) { order: 2; }
.content-hub-preview-card { overflow: hidden; }
.content-hub-preview-toolbar { flex: 0 0 auto; }
.content-hub-preview-frame { position: relative; min-height: 0; overflow: hidden; }
.content-hub-preview-frame iframe { display: block; width: 100%; height: 100%; border: 0; background: #fff; }

@media (min-width: 960px) {
  /* Sidebar cố định gọn hơn trên desktop để nhường thêm diện tích cho bảng dữ liệu. */
  .content-hub-sidebar { flex: 0 0 220px; max-width: 220px; }
  .content-hub-main { flex: 1 1 0; max-width: none; min-width: 0; }

  /* 240px đủ cho tên nhóm và thao tác, phần còn lại được nhường cho bảng để hiện nhiều checkbox hơn. */
  .content-hub-group-panel { flex: 0 0 240px; max-width: 240px; }
  .content-hub-question-panel { flex: 1 1 0; max-width: none; min-width: 0; }
}

/* Giữ ba lựa chọn media cùng mật độ và trạng thái như màn Soạn bài tập. */
.media-type-tabs {
	display: grid;
	grid-template-columns: repeat(3, minmax(0, 1fr));
	gap: 6px;
}
.media-type-tab {
	min-height: 54px;
	border: 1px solid #dce4e8;
	border-radius: 8px !important;
	color: #45515b !important;
	display: flex;
	flex-direction: column;
	gap: 3px;
	font-size: 12px;
	font-weight: 500;
	letter-spacing: .02em;
	text-transform: none;
}
.media-type-tab--active {
	border-color: #8fd1aa !important;
	background: #edf9f1 !important;
	color: #087b43 !important;
	font-weight: 700;
}
.media-type-dot {
	width: 7px;
	height: 7px;
	border-radius: 50%;
	background: #25a55a;
	position: absolute;
	margin: -22px 0 0 34px;
}
.media-input-row {
	display: flex;
	align-items: flex-start;
	gap: 8px;
}
.media-input-row .v-input { flex: 1 1 auto; min-width: 0; }
.media-input-row .v-btn { flex: 0 0 auto; min-height: 40px; }
.assignment-media-empty {
	min-height: 110px;
	display: flex;
	flex-direction: column;
	align-items: center;
	justify-content: center;
	gap: 6px;
	color: #78909c;
	border: 1px dashed #b0bec5;
	border-radius: 8px;
	background: #fafcfd;
}
.assignment-media-video-card {
	position: relative;
	overflow: hidden;
	border: 1px solid #e0e0e0;
	border-radius: 8px;
	background: #fff;
}
.assignment-media-video { display: block; width: 100%; min-height: 230px; border: 0; }
.assignment-media-image-grid {
	display: grid;
	grid-template-columns: repeat(auto-fill, minmax(130px, 1fr));
	gap: 8px;
}
.assignment-media-image-card,
.assignment-media-file-card {
	position: relative;
	overflow: hidden;
	border: 1px solid #e0e0e0;
	border-radius: 8px;
	background: #fff;
}
.assignment-media-video-card .media-card-footer,
.assignment-media-image-card .media-card-footer,
.assignment-media-file-card .media-card-footer {
	min-height: 42px;
	display: flex;
	align-items: center;
	justify-content: space-between;
	gap: 8px;
	padding-left: 8px;
}
.assignment-media-video-card .media-card-footer > span,
.assignment-media-image-card .media-card-footer > span,
.assignment-media-file-card .media-card-footer > span { min-width: 0; }
.media-card-delete {
	flex: 0 0 28px;
	width: 28px;
	height: 28px;
	min-width: 28px;
	padding: 0;
	opacity: .78;
	color: #d9535f !important;
	border-radius: 6px !important;
	border: 0 !important;
	box-shadow: none !important;
	background: transparent !important;
}
.media-card-delete:hover { opacity: 1; background: #fff1f2 !important; }
.media-card-delete .v-btn__overlay,
.media-card-delete .v-btn__underlay { display: none !important; }
.assignment-media-image-preview { height: 140px; }
.assignment-media-image-error { height: 100%; display: flex; flex-direction: column; align-items: center; justify-content: center; gap: 4px; color: #78909c; background: #f8fafb; }
.assignment-media-file-list {
	display: grid;
	grid-template-columns: repeat(auto-fit, minmax(260px, 1fr));
	gap: 10px;
}
.assignment-media-file-fallback {
	height: 100px;
	display: flex;
	align-items: center;
	justify-content: center;
	gap: 8px;
	color: #607d8b;
	background: #f8fafb;
	padding: 0 10px;
}
@media (max-width: 959px) {
	.content-hub-layout { height: auto; overflow: visible; }
	.content-hub-sidebar, .content-hub-main { height: auto; overflow: visible; }
	.content-hub-sidebar { display: block; min-height: auto; }
	.content-hub-branch-section { min-height: auto; overflow: visible; }
	.content-hub-documents, .content-hub-questions { height: auto; overflow: visible; }
	.content-hub-questions { padding: 12px; }
	.content-hub-question-row { height: auto; }
	.content-hub-question-panel { display: block; height: auto; overflow: visible; }
	.question-list-content { display: block; height: auto; overflow: visible; }
	.content-hub-group-panel { min-height: 0; padding: 0; border-right: 0; border-bottom: 1px solid rgba(0, 0, 0, .12); }
	.content-hub-question-panel { min-height: 0; padding: 0; padding-top: 12px; }
	.content-hub-group-panel, .content-hub-question-panel { flex: 0 0 100%; max-width: 100%; }
	.question-group-content, .question-list-content { padding-left: 0; padding-right: 0; }
	.question-search-field { max-width: none; flex: 1 1 140px; }
	.content-hub-empty-state { min-height: 200px; padding: 24px 12px; }
	.content-hub-media-input-row { flex-direction: column; }
	.content-hub-media-input-row > .v-btn { align-self: flex-start; }
	.content-hub-media-video { min-height: 180px; }
}
</style>
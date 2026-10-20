<template>
	<Global>
		<v-card>
			<!-- Header -->
			<v-card-title class="d-flex align-center flex-wrap ga-2">
				<span>{{ pageTitle }}</span>
				<span v-if="vueData.CapID">• {{ titleCap }}</span>
				<v-chip v-if="hasStudents" color="primary" variant="text" class="font-weight-medium" size="small">
					{{ DSHocSinh.length }} {{ isEn ? 'students' : 'học sinh' }}
				</v-chip>

				<!-- Danh sách cột điểm -->
				<div v-if="hasStudents && displayColumns.length > 0">
					<!-- Đã khóa hết: hiển thị gọn -->
					<v-menu v-if="isAllColumnsLocked" v-model="action.showAllLockedColumns" offset-y>
						<template v-slot:activator="{ props }">
							<v-chip v-bind="props" color="primary" variant="flat" size="small" label
								style="cursor:pointer">
								<v-icon start size="small" color="white">mdi-lock</v-icon>
								{{ displayColumns.length }}/{{ displayColumns.length }} {{ isEn ? 'columns locked' : 'cột đã khóa' }}
							</v-chip>
						</template>
						<v-list density="compact" max-height="300" class="overflow-y-auto">
							<v-list-item v-for="cotDiem in displayColumns" :key="cotDiem.value">
								<template v-slot:prepend>
									<v-icon size="small" start>mdi-lock</v-icon>
								</template>
								<v-list-item-title>{{ cotDiem.title }}</v-list-item-title>
							</v-list-item>
						</v-list>
					</v-menu>

					<!-- Chưa khóa hết -->
					<div v-else class="d-flex flex-wrap ga-2 align-center">
						<!-- Chỉ giữ bốn chip đầu ở hàng tiêu đề; các cột còn lại nằm trong menu để hàng không quá chật. -->
						<v-tooltip v-for="cotDiem in displayColumns.slice(0, 4)" :key="cotDiem.value"
							:text="isColumnReadyToLock(cotDiem.value) ? (isEn ? 'All grades entered — ready to lock!' : 'Đã nhập đủ điểm — sẵn sàng khóa!') : ''"
							:disabled="!isColumnReadyToLock(cotDiem.value)" location="bottom">
							<template v-slot:activator="{ props: tooltipProps }">
								<v-chip v-bind="tooltipProps"
									:color="cotDiem.isLocked ? 'primary' : (isColumnReadyToLock(cotDiem.value) ? 'warning' : 'grey')"
									:variant="cotDiem.isLocked ? 'flat' : (isColumnReadyToLock(cotDiem.value) ? 'tonal' : 'outlined')"
									size="small" label>
									<v-icon start v-if="cotDiem.isLocked" size="small" color="white">mdi-lock</v-icon>
									<v-icon start v-else-if="isColumnReadyToLock(cotDiem.value)" size="small"
										color="warning">mdi-lock-clock</v-icon>
									<v-icon start v-else size="small" color="grey">mdi-lock-open-variant-outline
									</v-icon>
									{{ cotDiem.title }}
								</v-chip>
							</template>
						</v-tooltip>

						<v-menu v-if="displayColumns.length > 4" offset-y>
							<template v-slot:activator="{ props }">
								<v-chip v-bind="props"
									:color="displayColumns.slice(4).some(c => isColumnReadyToLock(c.value)) ? 'warning' : 'grey-lighten-1'"
									:variant="displayColumns.slice(4).some(c => isColumnReadyToLock(c.value)) ? 'tonal' : 'outlined'"
									size="small" label>
									+{{ displayColumns.length - 4 }} {{ isEn ? 'other columns' : 'cột khác' }}
									<v-icon v-if="displayColumns.slice(4).some(c => isColumnReadyToLock(c.value))" end
										size="x-small">mdi-lock-clock</v-icon>
								</v-chip>
							</template>
							<v-list density="compact" max-height="300" class="overflow-y-auto">
								<v-list-item v-for="cotDiem in displayColumns.slice(4)" :key="cotDiem.value">
									<template v-slot:prepend>
										<v-icon v-if="cotDiem.isLocked" size="small" start>mdi-lock</v-icon>
										<v-icon v-else-if="isColumnReadyToLock(cotDiem.value)" size="small"
											color="warning" start>mdi-lock-clock</v-icon>
										<v-icon v-else size="small" color="grey" start>mdi-lock-open-variant-outline
										</v-icon>
									</template>
									<v-list-item-title>
										{{ cotDiem.title }}
										<span v-if="isColumnReadyToLock(cotDiem.value)"
											class="text-caption text-warning ml-1">· {{ isEn ? 'ready to lock' : 'sẵn sàng khóa' }}</span>
									</v-list-item-title>
								</v-list-item>
							</v-list>
						</v-menu>
					</div>
				</div>

				<v-spacer />
				<v-btn-toggle v-model="isEn" size="small" class="ml-auto">
					<v-btn :value="false" :disabled="!isEn" :color="!isEn ? 'green' : 'white'" @click="setLanguage(false)">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Viet.png" width="30" />
					</v-btn>
					<v-btn :value="true" :disabled="isEn" :color="isEn ? 'green' : 'white'" @click="setLanguage(true)">
						<v-img src="/_cdn/lhbs-lms/img_page_ph/Anh.png" width="30" />
					</v-btn>
				</v-btn-toggle>
			</v-card-title>

			<!-- Filter -->
			<v-card-text>
				<uc-filter ref="filterRef" v-model="filter" :is-en="isEn" @onRefresh="onRefresh" />
			</v-card-text>
			<v-divider />

			<!-- Toolbar -->
			<v-card-text class="py-2 d-flex align-center ga-2 flex-wrap">
				<v-btn v-if="!isAllColumnsLocked" @click="onLuuTam" color="grey" variant="outlined"
					:disabled="isDisabled" size="small">
					<v-icon start>mdi-content-save</v-icon>
					{{ isEn ? 'Save draft' : 'Lưu tạm' }}
					<v-badge v-if="changedCellCount > 0" :content="changedCellCount" color="primary" inline
						class="ml-1" />
				</v-btn>

				<v-btn v-if="!isAllColumnsLocked && vueData.user.UserID === 'NA0000022'" @click="onLuuTamTatCa"
					color="deep-orange" variant="outlined" :disabled="isDisabled || !hasStudents" size="small">
					<v-icon start>mdi-content-save-all</v-icon>
					{{ isEn ? 'Save all drafts' : 'Lưu tạm tất cả' }}
				</v-btn>

				<!-- Nút Khóa cột điểm — mở dialog chọn cột, default check hết -->
				<v-btn v-if="hasStudents && !isAllColumnsLocked" @click="onOpenLockDialog" color="teal"
					variant="outlined" :disabled="isDisabled" size="small">
					<v-icon start>mdi-lock</v-icon>
					{{ isEn ? 'Lock grade columns' : 'Khóa cột điểm' }}
					<v-badge v-if="!dismissedSuggest && suggestLockColumns.length > 0"
						:content="suggestLockColumns.length" color="warning" inline class="ml-1" />
				</v-btn>

				<v-btn v-if="canManageUnlockColumns && hasStudents && lockedColumns.length > 0"
					@click="onOpenUnlockDialog" color="warning" variant="outlined" size="small">
					<v-icon start>mdi-lock-open-variant</v-icon>
					{{ isEn ? 'Unlock grade columns' : 'Mở khóa cột điểm' }}
				</v-btn>

				<v-btn v-if="filter.MonHocItem?.MonHocID === 5" @click="onOpenMauNhanXet" color="primary"
					variant="outlined" size="small" :disabled="!hasStudents">
					<v-icon start>mdi-comment-text-outline</v-icon>
					{{ isEn ? 'Comment templates' : 'Mẫu nhận xét' }}
				</v-btn>

				<v-btn v-if="hasTextColumn" @click="onCheckCommentAI" color="purple" variant="outlined" size="small"
					:disabled="isDisabled || !hasStudents || isCheckingLength" :loading="isCheckingAI">
					<v-icon start>mdi-robot-outline</v-icon>
					{{ isEn ? 'Check comments with AI' : 'Kiểm tra nhận xét bằng AI' }}
				</v-btn>

				<v-btn v-if="isCap1NangLucPhamChat && hasTextColumn" @click="onCheckCommentLength" color="info"
					variant="outlined" size="small" :disabled="isDisabled || !hasStudents || isCheckingAI"
					:loading="isCheckingLength">
					<v-icon start>mdi-text-box-search-outline</v-icon>
					{{ isEn ? 'Check comment length' : 'Kiểm tra độ dài nhận xét' }}
				</v-btn>

				<v-btn v-if="showGetThemeTestButton" @click="onGetDiemTest" color="primary" variant="outlined"
					size="small" :disabled="!hasStudents">
					<v-icon start>mdi-download-outline</v-icon>
					{{ isEn ? 'Get Test scores' : 'Lấy điểm Test' }}
				</v-btn>

				<v-menu>
					<template v-slot:activator="{ props }">
						<v-btn v-bind="props" color="primary" variant="outlined" size="small" :disabled="!hasStudents"
							:loading="action.exportDialog.loading">
							<v-icon start>mdi-microsoft-excel</v-icon>
							{{ isEn ? 'Export Excel' : 'Xuất Excel' }}
							<v-icon end>mdi-menu-down</v-icon>
						</v-btn>
					</template>
					<v-list density="compact">
						<v-list-item @click="onExportExcel">
							<template v-slot:prepend>
								<v-icon size="small">mdi-file-excel-outline</v-icon>
							</template>
							<v-list-item-title>{{ isEn ? 'Export current class' : 'Xuất lớp hiện tại' }}</v-list-item-title>
						</v-list-item>
						<v-list-item @click="onOpenExportManyClassesDialog">
							<template v-slot:prepend>
								<v-icon size="small">mdi-table-multiple</v-icon>
							</template>
							<v-list-item-title>{{ isEn ? 'Export multiple classes' : 'Xuất nhiều lớp' }}</v-list-item-title>
						</v-list-item>
					</v-list>
				</v-menu>
			</v-card-text>

			<v-divider v-if="hasStudents" />

			<!-- Khu vực thông báo -->
			<v-card-text v-if="hasStudents" class="py-2 d-flex flex-column ga-2">
				<!-- Gợi ý khóa cột điểm khi đã nhập đủ -->
				<v-alert v-if="showSuggestLockAlert" type="success" variant="tonal" density="compact" closable
					@click:close="onDismissSuggestLock">
					<div class="d-flex align-center justify-space-between flex-wrap ga-3">
						<div>
							<div class="text-body-2 font-weight-bold">
								{{ isEn ? 'All grades entered — ' : 'Đã nhập đủ điểm — ' }}
								{{ suggestLockColumns.length === 1 ? '"' + suggestLockColumns[0].title + '"' :
								suggestLockColumns.length + (isEn ? ' columns' : ' cột') }}
								{{ isEn ? ' ready to lock!' : ' sẵn sàng chốt!' }}
							</div>
							<div class="text-caption text-medium-emphasis mt-1">
								{{ isEn ? 'Lock columns to finalize data; teachers will not be able to edit further.' : 'Khóa cột điểm để chốt dữ liệu, giáo viên sẽ không thể chỉnh sửa thêm.' }}
								<template v-if="suggestLockColumns.length > 1">
									<br />{{ isEn ? 'Columns: ' : 'Các cột: ' }}<span class="font-weight-medium">{{ suggestLockColumns.map(c =>
										c.title).join(' · ') }}</span>
								</template>
							</div>
						</div>
						<div class="d-flex ga-2">
							<v-btn size="small" color="success" variant="flat" @click.stop="onLockSuggestedColumns">
								<v-icon start size="small">mdi-lock-check</v-icon>
								{{ isEn ? 'Lock now' : 'Chốt & khóa ngay' }}
							</v-btn>
						</div>
					</div>
				</v-alert>

				<!-- Thông báo từ chối -->
				<v-alert v-if="reasonReject.disabled" type="error" variant="tonal" density="compact">
					<div class="text-body-2 font-weight-medium">{{ reasonReject.textPerson }}</div>
					<div class="text-body-2 text-medium-emphasis">
						{{ isEn ? 'Reason: ' : 'Lý do: ' }}<span class="font-weight-medium">{{ reasonReject.NoiDungNhanXet }}</span>
					</div>
				</v-alert>

				<!-- Hàng thông báo phụ -->
				<div class="d-flex ga-2 flex-wrap">
					<v-alert type="warning" variant="tonal" density="compact" style="width: fit-content">
						<div class="text-caption text-medium-emphasis">
							<template v-if="isEn">
								Comments <b>(red)</b> are grades entered by <b>other Teachers</b>
							</template>
							<template v-else>
								Comment <b>(màu đỏ)</b> là ô điểm do <b>Giáo viên khác</b> nhập
							</template>
							<span class="ml-4">
								<v-icon color="deep-purple">mdi-history</v-icon>
								{{ isEn ? 'History icon means this cell has grade history' : 'Biểu tượng lịch sử là ô đã có lịch sử chỉnh sửa' }}
							</span>
						</div>
					</v-alert>
					<v-alert v-if="formulaMismatchCells.length" type="warning" variant="tonal" density="compact"
						style="width: fit-content">
						<div class="text-caption">
							<b>{{ isEn ? 'Formula value differed at load' : 'Ô công thức lệch lúc tải bảng' }}</b>
							— {{ isEn ? formulaMismatchCells.length + ' amber cell(s) had an initial sheet value different from the saved API value.' : formulaMismatchCells.length + ' ô nền cam có kết quả lúc tải bảng khác với giá trị API đã lưu.' }}
							{{ isEn ? 'Hover over a cell to compare the initial values. Saving remains available.' : 'Di chuột vào ô để xem hai giá trị lúc tải; vẫn lưu bình thường.' }}
						</div>
					</v-alert>
					<v-alert v-if="showStarConversionRule" type="info" variant="tonal" density="compact"
						style="width: fit-content">
						<div class="text-caption">
							<b>{{ isEn ? 'Star conversion:' : 'Đổi sao:' }}</b> ≥9 = 5⭐ · ≥7 = 4⭐ · ≥5 = 3⭐ · {{ isEn ? 'others' : 'còn lại' }} = 2⭐
						</div>
					</v-alert>
				</div>
			</v-card-text>

			<!-- Jexcel Table -->
			<v-card-text class="pa-0 fontSizeCustom" ref="tableWrapper">
				<!-- Header công thức có DOM icon riêng; tooltip chỉ gắn với icon của cột công thức. -->
				<uc-jexcel v-if="hasStudents" :key="keyComp" v-model="instance" v-model:dataSource="DSHocSinh"
					class="hExcel" :freeze-columns="freezeColumns" :columns="headers" :comments="comments"
					:styleSheet="styleSheet" :nestedHeaders="shouldShowNestedHeaders ? nestedHeaders : []"
					:rootDataSource="DSHocSinh_API" @onChange="onChangeSheet" :context-menu="onGradeContextMenu" :filters="true"
					:style="{ '--excel-max-height': excelMaxHeight }" />
				<uc-card-empty v-else />
			</v-card-text>
		</v-card>

		<!-- Tooltip thường chỉ hiện công thức khi người dùng rê hoặc bấm icon của cột công thức. -->
		<v-tooltip v-model="formulaTooltipOpen" :activator="formulaTooltipActivator"
			:open-on-click="false" :open-on-hover="false" location="top" max-width="560">
			<div class="text-body-2 text-break">{{ formulaTooltipText }}</div>
		</v-tooltip>

		<!-- Dialog Khóa Cột Điểm -->
		<v-dialog v-model="action.lockDialog.show" max-width="480" persistent>
			<v-card rounded="lg">
				<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
					<v-icon color="teal" size="22">mdi-lock</v-icon>
					<span class="text-body-1 font-weight-bold">{{ isEn ? 'Lock grade columns' : 'Khóa cột điểm' }}</span>
				</v-card-title>
				<v-divider />

				<v-card-text class="pt-3 px-4 pb-2">
					<div class="text-body-2 text-medium-emphasis mb-3">
						{{ isEn ? 'Select grade columns to lock. Teachers will not be able to edit after locking.' : 'Chọn các cột điểm muốn khóa. Giáo viên sẽ không thể chỉnh sửa sau khi khóa.' }}
					</div>

					<!-- Check all — chỉ tính cột nhập tay chưa khóa -->
					<div class="d-flex align-center mb-1">
						<v-checkbox
							:model-value="action.lockDialog.selectedColumns.length === selectableColumns.length && selectableColumns.length > 0"
							:indeterminate="action.lockDialog.selectedColumns.length > 0 && action.lockDialog.selectedColumns.length < selectableColumns.length"
							@update:model-value="onToggleSelectAllLockColumns" density="compact" hide-details
							color="teal">
							<template v-slot:label>
								<span class="text-body-2 font-weight-medium">{{ isEn ? 'Select all' : 'Chọn tất cả' }}</span>
								<span class="text-caption text-medium-emphasis ml-2">({{
									action.lockDialog.selectedColumns.length }}/{{ selectableColumns.length }})</span>
							</template>
						</v-checkbox>
					</div>

					<v-divider class="mb-1" />

					<v-list density="compact" class="rounded border pa-0" style="max-height: 260px; overflow-y: auto;">
						<v-list-item v-for="(col, i) in lockableColumns" :key="col.value"
							:class="i < lockableColumns.length - 1 ? 'border-b' : ''" min-height="40"
							:disabled="col.isLocked" @click="!col.isLocked && onToggleLockColumn(col.value)">
							<template v-slot:prepend>
								<v-checkbox-btn
									:model-value="col.isLocked || action.lockDialog.selectedColumns.includes(col.value)"
									:disabled="col.isLocked" @update:model-value="onToggleLockColumn(col.value)"
									color="teal" density="compact" />
							</template>
							<v-list-item-title class="text-body-2">{{ col.title }}</v-list-item-title>
							<template v-slot:append>
								<v-chip v-if="col.isLocked" size="x-small" color="primary" variant="flat">{{ isEn ? 'Locked' : 'Đã khóa' }}
								</v-chip>
								<v-chip v-else-if="isColumnReadyToLock(col.value)" size="x-small" color="warning"
									variant="tonal">{{ isEn ? 'Full scores' : 'Đủ điểm' }}</v-chip>
							</template>
						</v-list-item>
					</v-list>
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end ga-2 pa-3">
					<v-btn variant="text" color="grey" @click="action.lockDialog.show = false">{{ isEn ? 'Cancel' : 'Hủy' }}</v-btn>
					<v-btn color="teal" variant="flat" :disabled="action.lockDialog.selectedColumns.length === 0"
						@click="onConfirmLockColumns">
						<v-icon start size="18">mdi-lock-check</v-icon>
						{{ isEn ? ('Lock ' + action.lockDialog.selectedColumns.length + ' columns') : ('Khóa ' + action.lockDialog.selectedColumns.length + ' cột') }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Chọn Cột Kiểm Tra Bằng AI -->
		<v-dialog v-model="action.aiColumnDialog.show" max-width="400" persistent>
			<v-card rounded="lg">
				<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
					<v-icon color="purple" size="22">mdi-robot-outline</v-icon>
					<span class="text-body-1 font-weight-bold">{{ isEn ? 'Select columns for AI check' : 'Chọn cột kiểm tra bằng AI' }}</span>
				</v-card-title>
				<v-divider />

				<v-card-text class="pt-3 px-4 pb-2">
					<div class="text-body-2 text-medium-emphasis mb-3">
						{{ isEn ? 'Select comment columns you want AI to check for spelling and grammar.' : 'Chọn các cột nhận xét bạn muốn AI kiểm tra lỗi chính tả và cú pháp.' }}
					</div>

					<v-list density="compact" class="rounded border pa-0" style="max-height: 200px; overflow-y: auto;">
						<v-list-item v-for="(col, i) in textColumns" :key="col.value"
							:class="i < textColumns.length - 1 ? 'border-b' : ''" min-height="40"
							:disabled="col.isLocked" @click="!col.isLocked && onToggleAiColumn(col.value)">
							<template v-slot:prepend>
								<v-checkbox-btn :model-value="action.aiColumnDialog.selectedColumns.includes(col.value)"
									:disabled="col.isLocked" @update:model-value="onToggleAiColumn(col.value)"
									color="purple" density="compact" />
							</template>
							<v-list-item-title class="text-body-2">
								{{ col.title }}
								<span v-if="aiRunCounts[col.value]"
									class="text-caption text-purple ml-2 font-weight-medium">
									{{ isEn ? ('(Run ' + aiRunCounts[col.value] + ' times)') : ('(Đã chạy ' + aiRunCounts[col.value] + ' lần)') }}
								</span>
							</v-list-item-title>
							<template v-slot:append>
								<v-chip v-if="col.isLocked" size="x-small" color="primary" variant="flat">{{ isEn ? 'Locked' : 'Đã khóa' }}
								</v-chip>
							</template>
						</v-list-item>
					</v-list>
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end ga-2 pa-3 flex-wrap">
					<v-btn variant="text" color="grey" @click="action.aiColumnDialog.show = false" size="small">{{ isEn ? 'Cancel' : 'Hủy' }}
					</v-btn>

					<template v-if="hasSelectedRunBefore">
						<v-btn color="purple" variant="outlined" size="small"
							:disabled="action.aiColumnDialog.selectedColumns.length === 0"
							@click="onShowPreviousAiResult()">
							<v-icon start size="16">mdi-eye-outline</v-icon>
							{{ isEn ? 'View previous result' : 'Xem kết quả trước' }}
						</v-btn>
						<v-btn color="purple" variant="flat" size="small"
							:disabled="action.aiColumnDialog.selectedColumns.length === 0"
							@click="onConfirmCheckCommentAI(true)">
							<v-icon start size="16">mdi-refresh</v-icon>
							{{ isEn ? 'Rerun AI' : 'Chạy lại AI' }}
						</v-btn>
					</template>
					<template v-else>
						<v-btn color="purple" variant="flat" size="small"
							:disabled="action.aiColumnDialog.selectedColumns.length === 0"
							@click="onConfirmCheckCommentAI(false)">
							{{ isEn ? 'Confirm' : 'Xác nhận' }}
						</v-btn>
					</template>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Mở Khóa Cột Điểm -->
		<v-dialog v-if="canManageUnlockColumns" v-model="action.unlockDialog.show" max-width="520" persistent>
			<v-card rounded="lg">
				<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
					<v-icon color="warning" size="22">mdi-lock-open-variant</v-icon>
					<span class="text-body-1 font-weight-bold">{{ isEn ? 'Unlock grade columns' : 'Mở khóa cột điểm' }}</span>
				</v-card-title>
				<v-divider />

				<v-card-text class="pt-3 px-4 pb-2">
					<div class="text-body-2 text-medium-emphasis mb-3">
						{{ isEn ? 'Select grade columns to unlock and enter reason.' : 'Chọn các cột điểm cần mở khóa và nhập lý do.' }}
					</div>

					<div class="d-flex align-center mb-1">
						<v-checkbox
							:model-value="action.unlockDialog.selectedColumns.length === lockedColumns.length && lockedColumns.length > 0"
							:indeterminate="action.unlockDialog.selectedColumns.length > 0 && action.unlockDialog.selectedColumns.length < lockedColumns.length"
							@update:model-value="onToggleSelectAllUnlockColumns" density="compact" hide-details
							color="warning">
							<template v-slot:label>
								<span class="text-body-2 font-weight-medium">{{ isEn ? 'Select all locked columns' : 'Chọn tất cả cột đã khóa' }}</span>
								<span class="text-caption text-medium-emphasis ml-2">({{
									action.unlockDialog.selectedColumns.length }}/{{ lockedColumns.length }})</span>
							</template>
						</v-checkbox>
					</div>

					<v-divider class="mb-1" />

					<v-list density="compact" class="rounded border pa-0 mb-3"
						style="max-height: 220px; overflow-y: auto;">
						<v-list-item v-for="(col, i) in lockedColumns" :key="col.value"
							:class="i < lockedColumns.length - 1 ? 'border-b' : ''" min-height="40"
							@click="onToggleUnlockColumn(col.value)">
							<template v-slot:prepend>
								<v-checkbox-btn :model-value="action.unlockDialog.selectedColumns.includes(col.value)"
									@update:model-value="onToggleUnlockColumn(col.value)" color="warning"
									density="compact" />
							</template>
							<v-list-item-title class="text-body-2">{{ col.title }}</v-list-item-title>
							<template v-slot:append>
								<v-chip size="x-small" color="primary" variant="flat">{{ isEn ? 'Locked' : 'Đang khóa' }}</v-chip>
							</template>
						</v-list-item>
					</v-list>

					<v-textarea v-model="action.unlockDialog.reason" :label="isEn ? 'Unlock reason' : 'Lý do mở khóa'" rows="3" auto-grow
						:placeholder="isEn ? 'Enter reason to unlock columns...' : 'Nhập lý do mở khóa cột điểm...'" hide-details="auto" />
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end ga-2 pa-3">
					<v-btn variant="text" color="grey" @click="action.unlockDialog.show = false">{{ isEn ? 'Cancel' : 'Hủy' }}</v-btn>
					<v-btn color="warning" variant="flat" :disabled="action.unlockDialog.selectedColumns.length === 0"
						@click="onConfirmUnlockColumns">
						<v-icon start size="18">mdi-lock-open-variant</v-icon>
						{{ isEn ? ('Unlock ' + action.unlockDialog.selectedColumns.length + ' columns') : ('Mở khóa ' + action.unlockDialog.selectedColumns.length + ' cột') }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Mẫu Nhận Xét -->
		<uc-dialog-mau-nhan-xet v-model="action.isShowDialogMauNhanXet" :filter="filter" :DSHocSinh="DSHocSinh"
			@onSubmit="onXacNhanMauNhanXet" />

		<!-- Dialog Kết quả Kiểm tra AI / Độ dài -->
		<v-dialog v-model="action.aiResultDialog.show" max-width="600" scrollable>
			<v-card rounded="lg">
				<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
					<v-icon :color="action.aiResultDialog.title?.includes('AI') ? 'purple' : 'info'" size="22">
						{{ action.aiResultDialog.title?.includes('AI') ? 'mdi-robot-outline' :
						'mdi-text-box-search-outline' }}
					</v-icon>
					<span class="text-body-1 font-weight-bold">{{ action.aiResultDialog.title || (isEn ? 'Check results' : 'Kết quả kiểm tra') }}</span>
				</v-card-title>
				<v-divider />

				<v-card-text class="pa-4" style="max-height: 450px;">
					<!-- Bộ lọc chỉ hiển thị vượt ký tự nếu là dialog độ dài -->
					<div v-if="action.aiResultDialog.title?.includes('giới hạn ký tự') && aiWarnings.some(w => w.type === 'limit' || w.type === 'limit_ok')"
						class="mb-2">
						<v-switch v-model="showOnlyLimitExceeded" :label="isEn ? 'Only show students exceeding 400 characters' : 'Chỉ hiển thị học sinh vượt quá 400 ký tự'"
							color="error" density="compact" hide-details />
					</div>

					<div v-if="filteredAiWarnings.length === 0"
						class="d-flex flex-column align-center justify-center py-6 text-medium-emphasis">
						<v-icon size="48" color="success" class="mb-2">mdi-check-decagram</v-icon>
						<p class="text-body-2 font-weight-bold text-success">{{ isEn ? 'No errors detected!' : 'Không phát hiện lỗi nào!' }}</p>
						<p class="text-caption">
							{{ action.aiResultDialog.title?.includes('AI')
							? (isEn ? 'All comments are spelled correctly and within character limits.' : 'Tất cả nhận xét đều đúng chính tả và nằm trong giới hạn ký tự.')
							: (showOnlyLimitExceeded ? (isEn ? 'No students exceeded the 400 character limit.' : 'Không có học sinh nào vượt quá giới hạn 400 ký tự.') : (isEn ? 'All comments are valid and within character limits.' : 'Tất cả nhận xét đều hợp lệ và nằm trong giới hạn ký tự.')) }}
						</p>
					</div>

					<v-list v-else density="compact" class="pa-0">
						<div v-for="(warning, index) in filteredAiWarnings" :key="index" class="mb-3 pb-3"
							:class="index < filteredAiWarnings.length - 1 ? 'border-b' : ''">
							<div class="d-flex align-center justify-space-between mb-1">
								<span class="text-body-2 font-weight-bold text-primary">
									{{ isEn ? ('Row ' + warning.rowNum + ' — ' + warning.studentName) : ('Dòng ' + warning.rowNum + ' — ' + warning.studentName) }}
								</span>
								<v-chip size="x-small"
									:color="warning.type === 'limit' ? 'error' : (warning.type === 'limit_ok' ? 'success' : 'warning')"
									variant="tonal">
									{{ warning.type === 'limit' ? (isEn ? 'Character limit exceeded' : 'Vượt ký tự') : (warning.type === 'limit_ok' ? (isEn ? 'Remaining: ' + warning.remainingCount + ' chars' : 'Còn lại: ' + warning.remainingCount + ' ký tự') : (isEn ? 'Spelling/grammar error' : 'Lỗi chính tả/cú pháp')) }}
								</v-chip>
							</div>

							<div class="text-caption text-medium-emphasis mb-1">
								<strong>{{ isEn ? 'Subject:' : 'Môn:' }}</strong> {{ warning.subjectName }}
							</div>

							<!-- Nội dung nhận xét hiện tại -->
							<div class="text-caption bg-grey-lighten-4 pa-2 rounded mb-2 text-italic"
								style="white-space: pre-wrap;">
								"<span v-html="warning.currentHtml || warning.currentText"></span>"
							</div>

							<!-- Chi tiết lỗi / Gợi ý -->
							<div v-if="warning.type === 'limit'" class="text-caption text-error font-weight-medium">
								<v-icon size="14" class="mr-1" color="error">mdi-alert-circle-outline</v-icon>
								{{ warning.message }}
							</div>
							<div v-else-if="warning.type === 'limit_ok'"
								class="text-caption text-success font-weight-medium">
								<v-icon size="14" class="mr-1" color="success">mdi-check-circle-outline</v-icon>
								{{ warning.message }}
							</div>
							<div v-else class="text-caption">
								<div class="font-weight-medium text-warning mb-1">
									<v-icon size="14" class="mr-1" color="warning">mdi-alert-outline</v-icon>
									{{ isEn ? 'Detected spelling or spacing error:' : 'Phát hiện lỗi chính tả hoặc khoảng trắng:' }}
								</div>
								<ul class="pl-4">
									<li v-for="(sug, sIdx) in warning.suggestions" :key="sIdx"
										class="text-caption text-medium-emphasis" style="white-space: pre-wrap;">
										{{ sug }}
									</li>
								</ul>
								<div
									class="mt-2 d-flex align-center justify-space-between flex-wrap ga-2 border-t pt-2">
									<div class="text-success font-weight-medium" style="white-space: pre-wrap;">
										{{ isEn ? 'Suggested fix: ' : 'Gợi ý sửa đổi: ' }}"<span
											v-html="warning.correctedHtml || warning.correctedText"></span>"
									</div>
									<v-btn v-if="!warning.applied" size="x-small" color="success" variant="tonal"
										@click="onApplyAiSuggestion(warning)">
										<v-icon start size="14">mdi-check-bold</v-icon>
										{{ isEn ? 'Apply' : 'Áp dụng' }}
									</v-btn>
									<span v-else
										class="text-caption text-success font-weight-bold d-flex align-center ga-1">
										<v-icon size="16">mdi-check-decagram</v-icon>
										{{ isEn ? 'Applied' : 'Đã áp dụng' }}
									</span>
								</div>
							</div>
						</div>
					</v-list>
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end pa-3 ga-2">

					<v-btn :color="action.aiResultDialog.title?.includes('AI') ? 'purple' : 'info'" variant="flat"
						size="small" @click="action.aiResultDialog.show = false">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn v-if="hasSpellingWarningsToApply" color="success" variant="flat" size="small"
						@click="onApplyAllAiSuggestions">
						<v-icon start>mdi-check-all</v-icon>
						{{ isEn ? 'Apply all' : 'Áp dụng tất cả' }}
					</v-btn>
					<v-btn v-if="aiWarnings.length > 0" color="success" variant="outlined" size="small"
						@click="onExportAiWarnings">
						<v-icon start>mdi-microsoft-excel</v-icon>
						{{ isEn ? 'Export error Excel' : 'Xuất Excel lỗi' }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		<!-- Dialog Xuất Excel nhiều lớp -->
		<v-dialog v-model="action.exportDialog.show" max-width="520">
			<v-card rounded="lg">
				<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
					<v-icon color="primary" size="22">mdi-table-multiple</v-icon>
					<span class="text-body-1 font-weight-bold">{{ isEn ? 'Export Excel for multiple classes' : 'Xuất Excel nhiều lớp' }}</span>
				</v-card-title>
				<v-divider />

				<v-card-text class="pt-3 px-4 pb-2">
					<div class="text-body-2 text-medium-emphasis mb-3">
						{{ isEn ? ('Export classes for subject ' + (filter.MonHocItem?.TenMonHoc_HienThi || filter.MonHocItem?.MonHocName) + ' and group ' + (filter.MaNhomCotDiemItem?.TenNhomCotDiem_EN || filter.MaNhomCotDiemItem?.TenNhomCotDiem_VI) + '.') : ('Xuất các lớp cùng môn ' + (filter.MonHocItem?.TenMonHoc_HienThi || filter.MonHocItem?.MonHocName) + ' và cùng mã nhóm ' + filter.MaNhomCotDiemItem?.TenNhomCotDiem_VI + '.') }}
					</div>
					<v-select v-model="action.exportDialog.selectedLopIDs" :items="exportableClasses"
						item-title="TenLop" item-value="LopID" :label="isEn ? 'Select class' : 'Chọn lớp'" multiple chips closable-chips
						variant="outlined" density="compact" hide-details="auto" />
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end pa-3 ga-2">
					<v-btn variant="text" size="small" @click="action.exportDialog.show = false"
						:disabled="action.exportDialog.loading">{{ isEn ? 'Close' : 'Đóng' }}</v-btn>
					<v-btn color="primary" variant="flat" size="small" @click="onExportManyClasses"
						:loading="action.exportDialog.loading">
						<v-icon start>mdi-microsoft-excel</v-icon>
						{{ isEn ? 'Export Excel' : 'Xuất Excel' }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

			<!-- Dialog lịch sử điểm của đúng học sinh và cột điểm vừa chọn bằng chuột phải -->
			<v-dialog v-model="action.gradeHistoryDialog.show" max-width="860" scrollable>
				<v-card rounded="lg">
					<!-- Giữ mã học sinh ngay tiêu đề để xác định đúng người khi xem lịch sử từ bảng nhiều dòng. -->
					<v-card-title class="d-flex align-center ga-2 pt-4 pb-2 px-4">
						<v-icon color="primary" size="22">mdi-history</v-icon>
						<div>
							<div class="text-body-1 font-weight-bold">{{ isEn ? 'Grade history' : 'Lịch sử điểm' }}</div>
							<div class="text-caption text-medium-emphasis d-flex align-center flex-wrap ga-1">
								<span>{{ action.gradeHistoryDialog.studentName }}</span>
								<span>·</span>
								<span>{{ isEn ? 'Student ID: ' : 'Mã học sinh: ' }}{{ action.gradeHistoryDialog.studentId }}</span>
								<span>·</span>
								<span>{{ action.gradeHistoryDialog.columnTitle }}</span>
							</div>
						</div>
				</v-card-title>
				<v-divider />

				<v-card-text class="pa-4">
					<div v-if="action.gradeHistoryDialog.loading" class="d-flex justify-center py-6">
						<v-progress-circular indeterminate color="primary" />
					</div>
					<v-alert v-else-if="action.gradeHistoryDialog.error" type="error" variant="tonal" density="compact">
						{{ action.gradeHistoryDialog.error }}
					</v-alert>
					<v-alert v-else-if="action.gradeHistoryDialog.rows.length === 0" type="info" variant="tonal" density="compact">
						{{ isEn ? 'This cell has no previous grade history.' : 'Ô điểm này chưa có lịch sử thay đổi.' }}
					</v-alert>
					<v-table v-else density="compact" hover>
						<thead>
							<tr>
								<th>{{ isEn ? 'Time' : 'Thời gian' }}</th>
										<th>{{ isEn ? 'Value' : 'Giá trị' }}</th>
										<th>{{ isEn ? 'Entered by' : 'Người nhập' }}</th>
							</tr>
						</thead>
						<tbody>
											<tr v-for="(log, index) in action.gradeHistoryDialog.rows" :key="(log.KQHTID || 'log') + '_' + (log.NhapDiemTime || index) + '_' + index">
												<td>{{ log.NhapDiemTime || log.UpdateTime || log.CreateTime || '-' }}</td>
												<td>{{ log.KetQuaDanhGia_VI ?? '-' }}</td>
												<td>{{ getHistoryUserLabel(log) }}</td>
											</tr>
						</tbody>
					</v-table>
				</v-card-text>

				<v-divider />
				<v-card-actions class="justify-end pa-3">
					<v-btn variant="text" @click="action.gradeHistoryDialog.show = false">
						{{ isEn ? 'Close' : 'Đóng' }}
					</v-btn>
				</v-card-actions>
			</v-card>
		</v-dialog>

		</Global>
</template>

<script>
	export default {
		name: 'BangDiem',
		inject: ['snackbarRef', 'iframeRef', 'confirmRef'],

	props: {},

	data() {
		const isEn = JSON.parse(localStorage.getItem('IsLanguage')) ?? false;
		if (this.$i18n) {
			this.$i18n.locale = isEn ? 'en' : 'vi';
		}
		return {
			isEn,
			vueData,
			isCheckingAI: false,
			isCheckingLength: false,
			showOnlyLimitExceeded: false,

			action: {
				isShowDialogMauNhanXet: false,
				showAllLockedColumns: false,
				aiResultDialog: {
					show: false,
					title: 'Kết quả kiểm tra nhận xét bằng AI'
				},
				aiColumnDialog: {
					show: false,
					selectedColumns: []
				},
				lockDialog: {
					show: false,
					selectedColumns: []
				},
				unlockDialog: {
					show: false,
					selectedColumns: [],
					reason: ''
				},
				exportDialog: {
					show: false,
					selectedLopIDs: [],
					loading: false
				},
					gradeHistoryDialog: {
						show: false,
						loading: false,
						studentName: '',
						studentId: '',
						columnTitle: '',
					rows: [],
					error: ''
				}
			},

			aiWarnings: [],
			aiCache: {},
			aiRunCounts: {},
			gradeHistoryCache: {},
			gradeHistoryLoadId: 0,
			// Cache danh mục giáo viên để dialog hiển thị họ tên kèm mã, không gọi API lặp lại cho từng dòng log.
			teacherNameMap: {},
			teacherNameMapLoaded: false,
			teacherNameMapLoading: null,

			filter: {
				KhoiItem: null,
				LopItem: null,
				MonHocItem: null,
				MaNhomCotDiemItem: null,
				NienKhoa: vueData.NienKhoa
			},

			editedCells: [],
			DSKhoaCotDiem_API: [],
			DSCotDiem_ByMaNhomCotDiem: [],
			DSHocSinh_API: [],
			DSHocSinh: [],
			displayColumns: [],

			tinhTrangStatus: {
				isDisabled: false,
				TinhTrang: null,
				statusDetail: null
			},

			suggestLockColumns: [],
			dismissedSuggest: false,

			excelMaxHeight: '400px',
			_resizeObserver: null,

			headers: [],
			nestedHeaders: [],
			freezeColumns: 3,
			comments: {},
			styleSheet: {},
			formulaMismatchCells: [],
			formulaMismatchOriginalStyles: {},
			instance: null,
			formulaTooltipOpen: false,
			formulaTooltipActivator: null,
			formulaTooltipText: '',
			formulaTooltipEventHandler: null,
			keyComp: 0
		};
	},

	computed: {
		pageTitle() {
			if (this.isEn) return 'Enter Grades';
			return this.vueData.TitlePage || 'Nhập điểm';
		},
		titleCap() {
			const capId = parseInt(this.vueData.CapID);
			if (this.isEn) {
				if (capId === 1) return 'Primary School';
				if (capId === 2) return 'Secondary School';
				if (capId === 3) return 'High School';
				return `Level ${capId}`;
			}
			return `Cấp ${capId}`;
		},

		hasTextColumn() {
			return this.DSCotDiem_ByMaNhomCotDiem?.some(col => col.GiaTriCotDiem === 'text');
		},

		isCap1NangLucPhamChat() {
			const isCap1 = parseInt(this.vueData.CapID) === 1;
			const monHocID = this.filter.MonHocItem?.MonHocID;
			const mapMonHocToNhom = {
				20: 'Năng lực chung', 21: 'Năng lực chung', 22: 'Năng lực chung',
				28: 'Năng lực đặc thù', 29: 'Năng lực đặc thù', 30: 'Năng lực đặc thù',
				31: 'Năng lực đặc thù', 32: 'Năng lực đặc thù', 33: 'Năng lực đặc thù',
				34: 'Năng lực đặc thù',
				23: 'Phẩm chất', 24: 'Phẩm chất', 25: 'Phẩm chất', 26: 'Phẩm chất', 27: 'Phẩm chất'
			};
			return isCap1 && !!mapMonHocToNhom[monHocID];
		},

		hasStudents() {
			return this.DSHocSinh?.length > 0;
		},

		currentSubjectId() {
			return this.filter.MonHocItem?.MonHocID;
		},

		isEnglishSubject() {
			return BangDiemService.filter.isEnglishSubject(this.currentSubjectId);
		},

		isGroupSubject() {
			return BangDiemService.filter.isGroupSubject(this.currentSubjectId);
		},

		isDisabled() {
			if (!this.hasStudents) return true;
			if (this.isAllColumnsLocked) return true;
			return this.tinhTrangStatus?.isDisabled ?? false;
		},

		isAllColumnsLocked() {
			if (!this.displayColumns.length) return false;
			return this.displayColumns.every(col => col.isLocked);
		},

		lockedColumns() {
			return this.displayColumns.filter(col => col.isLocked);
		},

		// Danh sách tài khoản được nghiệp vụ ủy quyền mở khóa cột điểm; điều kiện dữ liệu của nút vẫn được kiểm tra ở template.
		canManageUnlockColumns() {
			const unlockUserIds = ['NA0000022', 'NV0000134', 'NV0000009', 'NV0000018'];
			return unlockUserIds.includes(this.vueData?.user?.UserID);
		},

		/** Tất cả cột trong dialog khóa */
		lockableColumns() {
			return this.displayColumns;
		},

		/** Cột có thể tick checkbox (chưa khóa) */
		selectableColumns() {
			return this.displayColumns.filter(col => !col.isLocked);
		},

		shouldShowNestedHeaders() {
			return this.filter.MaNhomCotDiemItem?.MaNhomCotDiem === 'TatCa';
		},

		reasonReject() {
			const info = BangDiemService.utility.getReasonReject(this.DSHocSinh_API, this.vueData);
			return {
				...info,
				textPerson: BangDiemService.utility.renderTextPersonReject(info.TinhTrang, this.vueData)
			};
		},

		showSuggestLockAlert() {
			return this.hasStudents && !this.isDisabled && !this.dismissedSuggest && this.suggestLockColumns.length > 0;
		},

		showStarConversionRule() {
			return BangDiemService.filter.isMonHocConvertWithStar(this.currentSubjectId) && this.filter.MaNhomCotDiemItem !== null;
		},

		showGetThemeTestButton() {
			if (!this.filter.MaNhomCotDiemItem || this.currentSubjectId !== 76) return false;
			return ['Theme_2', 'Theme_4', 'Theme_6', 'Theme_8'].includes(this.filter.MaNhomCotDiemItem.MaNhomCotDiem);
		},

		pendingSaveCells() {
			const cells = [...this.editedCells];
			const existingCoords = new Set(cells.map(cell => `${Number(cell.x)}:${Number(cell.y)}`));
			// Giữ snapshot ban đầu để cảnh báo, nhưng lưu giá trị công thức mới nhất sau khi giáo viên sửa dữ liệu đầu vào.
			this.formulaMismatchCells.forEach(mismatch => {
				const x = Number(mismatch.columnIndex);
				const y = Number(mismatch.rowIndex);
				if (!Number.isInteger(x) || !Number.isInteger(y)) return;
				const coord = `${x}:${y}`;
				if (existingCoords.has(coord)) return;
				existingCoords.add(coord);
				cells.push({
					x,
					y,
						value: mismatch.saveValue ?? mismatch.calculatedValue,
					formulaMismatch: true,
					studentId: mismatch.studentId,
					columnCode: mismatch.columnCode
				});
			});
			return cells;
		},

		changedCellCount() {
			return this.pendingSaveCells.length;
		},

		textColumns() {
			return this.DSCotDiem_ByMaNhomCotDiem?.filter(col => col.GiaTriCotDiem === 'text').map(col => {
				const matchedCol = this.displayColumns.find(d => d.value === col.value);
				return {
					title: matchedCol?.title || col.title,
					value: col.value,
					isLocked: matchedCol?.isLocked ?? false
				};
			}) || [];
		},

		suggestLockColumnSet() {
			return new Set(this.suggestLockColumns.map(c => c.value));
		},

		/** Danh sách cột chưa khóa (không phải công thức) — dùng cho onLockAllColumns */
		unlockedColumns() {
			return this.lockableColumns.filter(col => !col.isLocked);
		},

		hasSelectedRunBefore() {
			return this.action.aiColumnDialog.selectedColumns.some(colVal => 
				this.aiRunCounts && this.aiRunCounts[colVal] > 0
			);
		},

		exportableClasses() {
			return this.$refs.filterRef?.DSLop || [];
		},

		hasSpellingWarningsToApply() {
			return this.action.aiResultDialog.title?.includes('AI') && 
				this.aiWarnings?.some(w => w.type === 'spelling' && !w.applied);
		},
		hasBlockingDialog() {
			const action = this.action;
			return Boolean(action.isShowDialogMauNhanXet || action.aiResultDialog.show ||
				action.aiColumnDialog.show || action.lockDialog.show || action.unlockDialog.show ||
				action.exportDialog.show || action.gradeHistoryDialog.show);
		},
		filteredAiWarnings() {
			if (!this.aiWarnings) return [];
			if (this.action.aiResultDialog.title?.includes('giới hạn ký tự') && this.showOnlyLimitExceeded) {
				return this.aiWarnings.filter(w => w.type === 'limit');
			}
			return this.aiWarnings;
		}
	},

	watch: {
		formulaTooltipOpen(isOpen) {
			if (!isOpen) this.resetFormulaTooltipState();
		},
		hasBlockingDialog(isOpen) {
			// Ẩn tooltip khi dialog nghiệp vụ mở để nội dung không phủ lên dialog.
			if (isOpen) this.closeFormulaTooltip();
		},
		keyComp() {
			// JExcel dựng lại header khi key đổi; chèn icon sau khi DOM của bảng mới sẵn sàng.
			this.$nextTick(() => this.refreshFormulaHeaderIcons());
		},
		filter: {
			handler(newFilter) {
				if (!BangDiemService.filter.isValidFilter(newFilter)) {
					this.resetData();
				}
			},
			deep: true
		}
	},

	mounted() {
		window.addEventListener('storage', (e) => {
			if (e.key === 'IsLanguage') {
				const isEn = JSON.parse(e.newValue) ?? false;
				this.isEn = isEn;
				if (this.$i18n) this.$i18n.locale = isEn ? 'en' : 'vi';
				if (this.hasStudents) {
					this.onRefresh();
				}
			}
		});
		this._updateExcelHeight();
		this._resizeObserver = new ResizeObserver(() => { this._updateExcelHeight(); });
		this._resizeObserver.observe(this.$el);
		const tableWrapper = this.$refs.tableWrapper?.$el || this.$refs.tableWrapper;
		if (tableWrapper) {
			this.formulaTooltipEventHandler = (event) => this.onFormulaHeaderTooltip(event);
			tableWrapper.addEventListener('mouseover', this.formulaTooltipEventHandler);
			tableWrapper.addEventListener('mouseout', this.formulaTooltipEventHandler);
			tableWrapper.addEventListener('click', this.formulaTooltipEventHandler, true);
			tableWrapper.addEventListener('keydown', this.formulaTooltipEventHandler, true);
			tableWrapper.addEventListener('focusout', this.formulaTooltipEventHandler);
		}
		this.$nextTick(() => this.refreshFormulaHeaderIcons());
	},

	beforeUnmount() {
		const tableWrapper = this.$refs.tableWrapper?.$el || this.$refs.tableWrapper;
		if (tableWrapper && this.formulaTooltipEventHandler) {
			tableWrapper.removeEventListener('mouseover', this.formulaTooltipEventHandler);
			tableWrapper.removeEventListener('mouseout', this.formulaTooltipEventHandler);
			tableWrapper.removeEventListener('click', this.formulaTooltipEventHandler, true);
			tableWrapper.removeEventListener('keydown', this.formulaTooltipEventHandler, true);
			tableWrapper.removeEventListener('focusout', this.formulaTooltipEventHandler);
		}
		this.formulaTooltipOpen = false;
		this.formulaTooltipActivator = null;
		this.formulaTooltipEventHandler = null;
		if (this._resizeObserver) {
			this._resizeObserver.disconnect();
			this._resizeObserver = null;
		}
	},

	methods: {
		// JExcel render title thành text; chèn icon sau khi bảng dựng xong và chỉ trên header có metadata của cột công thức.
		refreshFormulaHeaderIcons() {
			const tableWrapper = this.$refs.tableWrapper?.$el || this.$refs.tableWrapper;
			if (!tableWrapper || !this.headers?.length) return;

			this.headers.forEach((column, columnIndex) => {
				const headerCells = Array.from(tableWrapper.querySelectorAll(
					`thead td[data-x="${columnIndex}"]`
				)).filter(cell => !cell.classList.contains('jss_column_filter'));
				const headerCell = headerCells[headerCells.length - 1];
				if (!headerCell) return;

				let icon = headerCell.querySelector('[data-formula-tooltip]');
				if (!column.formulaTooltipText) {
					if (icon) icon.remove();
					return;
				}

				if (!icon) {
					icon = document.createElement('span');
					icon.className = 'mdi mdi-information-outline ml-1';
					icon.setAttribute('role', 'button');
					icon.setAttribute('tabindex', '0');
					headerCell.appendChild(icon);
				}
				icon.setAttribute('aria-label', column.formulaTooltipText);
				icon.setAttribute('data-formula-tooltip', column.formulaTooltipText);
			});
		},

		onFormulaHeaderTooltip(event) {
			const icon = event.target?.closest?.('[data-formula-tooltip]');
			const tableWrapper = this.$refs.tableWrapper?.$el || this.$refs.tableWrapper;
			if (event.type === 'mouseout') {
				if (icon && !icon.contains(event.relatedTarget) && this.formulaTooltipActivator === icon) {
					this.closeFormulaTooltip();
				}
				return;
			}
			if (event.type === 'focusout') {
				if (icon && !icon.contains(event.relatedTarget) && this.formulaTooltipActivator === icon) {
					this.closeFormulaTooltip();
				}
				return;
			}
			if (!icon || !tableWrapper?.contains(icon)) {
				if (event.type === 'click' && this.formulaTooltipOpen) this.closeFormulaTooltip();
				return;
			}
			if (event.type === 'mouseover' && icon.contains(event.relatedTarget)) return;
			if (event.type === 'keydown' && !['Enter', ' '].includes(event.key)) return;
			if (event.type === 'mouseover') {
				this.openFormulaTooltip(icon);
				return;
			}
			if (event.type === 'click' || event.type === 'keydown') {
				event.preventDefault();
				event.stopPropagation();
				// Click chỉ mở tooltip; để pointer leave/focusout hoặc click ngoài bảng đóng nó.
				if (!this.formulaTooltipOpen || this.formulaTooltipActivator !== icon) {
					this.openFormulaTooltip(icon);
				}
			}
		},

		openFormulaTooltip(icon) {
			if (this.hasBlockingDialog) return;
			this.formulaTooltipActivator = icon;
			this.formulaTooltipText = icon.getAttribute('data-formula-tooltip') || '';
			this.formulaTooltipOpen = true;
		},

		resetFormulaTooltipState() {
			this.formulaTooltipActivator = null;
			this.formulaTooltipText = '';
		},

		closeFormulaTooltip() {
			this.formulaTooltipOpen = false;
			this.resetFormulaTooltipState();
		},

		setLanguage(val) {
			this.isEn = val;
			if (this.$i18n) this.$i18n.locale = val ? 'en' : 'vi';
			localStorage.setItem('IsLanguage', JSON.stringify(val));
			if (this.hasStudents) {
				this.onRefresh();
			}
		},
		showSnackbar(message, color = 'info') {
			if (this.snackbarRef?.value?.showSnackbar) {
				this.snackbarRef.value.showSnackbar({ message, color });
				return;
			}
			Vue.$toast[color]?.(message, { position: 'top' });
		},


		ensureUnlockPermission() {
			if (this.canManageUnlockColumns) return true;
			this.showSnackbar('Tính năng mở khóa cột điểm chỉ dành cho tài khoản được phân quyền.', 'warning');
			return false;
		},

		isColumnReadyToLock(maCotDiem) {
			return this.suggestLockColumnSet.has(maCotDiem);
		},

		_updateExcelHeight() {
			this.$nextTick(() => {
				const wrapper = this.$refs.tableWrapper?.$el ?? this.$refs.tableWrapper;
				if (!wrapper) return;
				const top = wrapper.getBoundingClientRect().top;
				const height = window.innerHeight - top - 16;
				this.excelMaxHeight = Math.max(height, 200) + 'px';
			});
		},

		checkSuggestLock() {
			const newSuggest = BangDiemService.data.getColumnsReadyToLock(
				this.DSHocSinh, this.DSCotDiem_ByMaNhomCotDiem, this.displayColumns, this.DSHocSinh_API
			);
			const oldKeys = this.suggestLockColumns.map(c => c.value).sort().join(',');
			const newKeys = newSuggest.map(c => c.value).sort().join(',');
			if (newKeys !== oldKeys) this.dismissedSuggest = false;
			this.suggestLockColumns = newSuggest;
		},

		onDismissSuggestLock() {
			this.dismissedSuggest = true;
		},

		// ============================================================
		// COLUMN LOCK DIALOG
		// ============================================================

		/** Khóa ngay các cột gợi ý từ alert (đã nhập đủ) */
		async onLockSuggestedColumns() {
			this.action.lockDialog.selectedColumns = this.suggestLockColumns.map(c => c.value);
			this.action.lockDialog.show = true;
		},

		// ============================================================
		// COLUMN LOCK DIALOG
		// ============================================================

		onOpenLockDialog() {
			const isSaved = this.DSHocSinh_API.some(hs => hs.KQHTID);
			if (!isSaved) {
				this.showSnackbar('Chưa có dữ liệu được lưu. Vui lòng lưu tạm trước khi khóa cột điểm!', 'warning');
				return;
			}
			// Default check hết các cột nhập tay chưa khóa
			this.action.lockDialog.selectedColumns = this.selectableColumns.map(col => col.value);
			this.action.lockDialog.show = true;
		},

		onToggleSelectAllLockColumns(val) {
			if (val) {
				this.action.lockDialog.selectedColumns = this.selectableColumns.map(col => col.value);
			} else {
				this.action.lockDialog.selectedColumns = [];
			}
		},

		onToggleLockColumn(value) {
			const idx = this.action.lockDialog.selectedColumns.indexOf(value);
			if (idx === -1) {
				this.action.lockDialog.selectedColumns = [...this.action.lockDialog.selectedColumns, value];
			} else {
				this.action.lockDialog.selectedColumns = this.action.lockDialog.selectedColumns.filter(v => v !== value);
			}
		},

		async ensureSavedBeforeLock() {
			const cellsToSave = this.pendingSaveCells;
			if (!cellsToSave.length) return true;

			const shouldSave = await this.confirmRef.value.show({
				title: 'Bạn có muốn lưu dữ liệu trước khi khóa cột điểm không?'
			});

			if (!shouldSave) return false;

			try {
				const success = await BangDiemService.saveData(
					cellsToSave, this.DSHocSinh, this.DSHocSinh_API,
					this.freezeColumns, { ...this.filter, NienKhoa: this.vueData.NienKhoa },
					this.instance, this.vueData
				);
				if (!success) return false;

				await BangDiemService.saveDraft(this.filter, this.vueData);
				this.showSnackbar('Đã lưu dữ liệu trước khi khóa cột điểm!', 'success');
				await this.onRefresh();
				return true;
			} catch (error) {
				console.error('ensureSavedBeforeLock error:', error);
				this.showSnackbar('Có lỗi xảy ra khi lưu dữ liệu trước khi khóa cột điểm!', 'error');
				return false;
			}
		},

		async onConfirmLockColumns() {
			const selectedCols = this.lockableColumns.filter(col =>
				this.action.lockDialog.selectedColumns.includes(col.value)
			);
			if (!selectedCols.length) return;

			const canContinue = await this.ensureSavedBeforeLock();
			if (!canContinue) return;

			const nlpcIDList = this.filter.MonHocItem?.List_MonHoc_NLPC_ID
				? this.filter.MonHocItem.List_MonHoc_NLPC_ID.split(',').map(id => id.trim()).filter(Boolean)
				: [];

			this.action.lockDialog.show = false;

			try {
				await BangDiemService.lock.lockColumns(selectedCols, this.filter);
				if (nlpcIDList.length > 0) {
					await BangDiemService.lock.lockNLPCColumns(this.filter, this.vueData, this.DSHocSinh_API);
				}
				// Dựng payload đồng bộ từ bảng sau khi khóa để log kiểm tra; request mark/lms_syncdiem vẫn được giữ comment.
				try {
					await BangDiemService.lock.logLmsSyncDiemParamsAfterLock(
						selectedCols, this.filter, this.vueData, this.instance, this.headers, this.DSHocSinh_API
					);
				} catch (payloadError) {
					// Payload preview không được làm hỏng thao tác khóa đã lưu thành công.
					console.warn('[mark/lms_syncdiem] Không thể dựng payload xem trước:', payloadError);
				}
				this.showSnackbar(
					nlpcIDList.length > 0
						? 'Đã khóa cột điểm và các môn Năng lực – Phẩm chất đi kèm!'
						: `Đã khóa ${selectedCols.length} cột điểm!`,
					'success'
				);
				await this.onRefresh();
			} catch (error) {
				console.error('onConfirmLockColumns error:', error);
				this.showSnackbar('Có lỗi xảy ra khi khóa cột điểm!', 'error');
			}
		},

		onOpenUnlockDialog() {
			if (!this.ensureUnlockPermission()) return;
			this.action.unlockDialog.selectedColumns = this.lockedColumns.map(col => col.value);
			this.action.unlockDialog.reason = '';
			this.action.unlockDialog.show = true;
		},

		onToggleSelectAllUnlockColumns(val) {
			if (val) {
				this.action.unlockDialog.selectedColumns = this.lockedColumns.map(col => col.value);
			} else {
				this.action.unlockDialog.selectedColumns = [];
			}
		},

		onToggleUnlockColumn(value) {
			const idx = this.action.unlockDialog.selectedColumns.indexOf(value);
			if (idx === -1) {
				this.action.unlockDialog.selectedColumns = [...this.action.unlockDialog.selectedColumns, value];
			} else {
				this.action.unlockDialog.selectedColumns = this.action.unlockDialog.selectedColumns.filter(v => v !== value);
			}
		},

		async onConfirmUnlockColumns() {
			if (!this.ensureUnlockPermission()) return;
			const selectedCols = this.lockedColumns.filter(col =>
				this.action.unlockDialog.selectedColumns.includes(col.value)
			);
			if (!selectedCols.length) return;

			const reason = (this.action.unlockDialog.reason || '').trim();
			if (!reason) {
				this.showSnackbar('Vui lòng nhập lý do mở khóa cột điểm!', 'warning');
				return;
			}

			this.action.unlockDialog.show = false;

			try {
				await BangDiemService.lock.unlockColumns(selectedCols, this.filter, reason);
				this.showSnackbar(`Đã mở khóa ${selectedCols.length} cột điểm!`, 'success');
				await this.onRefresh();
			} catch (error) {
				console.error('onConfirmUnlockColumns error:', error);
				this.showSnackbar('Có lỗi xảy ra khi mở khóa cột điểm!', 'error');
			}
		},

		// ============================================================
		// DATA
		// ============================================================

		resetData() {
			this.DSHocSinh_API = [];
			this.DSHocSinh = [];
			this.formulaMismatchCells = [];
			this.formulaMismatchOriginalStyles = {};
			this.headers = [];
			this.nestedHeaders = [];
			this.displayColumns = [];
			this.keyComp++;
			this.aiWarnings = [];
			this.aiRunCounts = {};
			this.gradeHistoryCache = {};
			this.gradeHistoryLoadId++;
		},

		async onRefresh() {
			try {
				const result = await BangDiemService.initialize(this.filter, this.vueData);

				this.DSHocSinh = result.students;
				this.DSHocSinh_API = result.apiData;
				this.headers = result.headers;
				this.nestedHeaders = result.nestedHeaders;
				this.freezeColumns = result.freezeColumns;
				this.styleSheet = result.styleSheet;
				this.comments = result.comments;
				this.DSKhoaCotDiem_API = result.lockedColumns;
				this.DSCotDiem_ByMaNhomCotDiem = result.DSCotDiem_ByMaNhomCotDiem;
				this.displayColumns = result.displayColumns;

				// Reset kết quả kiểm tra AI khi làm mới bảng điểm
				this.aiWarnings = [];
				this.aiRunCounts = {};
				this.gradeHistoryCache = {};
				const historyLoadId = ++this.gradeHistoryLoadId;

				// Auto-mark các ô có default value vào editedCells
				const defaultCells = [];
				result.students.forEach((student, rowIndex) => {
					result.DSCotDiem_ByMaNhomCotDiem.forEach((cotDiem, colIndex) => {
						const apiRow = result.apiData.find(
							x => x.HocSinhID === student.HocSinhID && x.MaCotDiem === cotDiem.value
						);
						if (apiRow?.KQHTID === 0 && student[cotDiem.value] != null && student[cotDiem.value] !== '') {
							defaultCells.push({ x: colIndex + result.freezeColumns, y: rowIndex, value: student[cotDiem.value] });
						}
					});
				});

				this.tinhTrangStatus = result.tinhTrangStatus;
				this.editedCells = defaultCells;
				this.checkSuggestLock();
				this.keyComp++;

				// Nạp log một lần cho cả lớp để đánh dấu các ô có lịch sử trước khi giáo viên mở chi tiết.
				this.$nextTick(() => {
					// Chụp một lần đối chiếu API với kết quả công thức ban đầu sau khi bảng JSpreadsheet tính xong.
					setTimeout(() => {
						if (historyLoadId === this.gradeHistoryLoadId) this.refreshFormulaMismatchMarkers();
					}, 0);
					this.loadGradeHistoryMarkers(result.students, result.apiData, historyLoadId);
				});
			} catch (error) {
				console.error('onRefresh error:', error);
				this.showSnackbar('Có lỗi xảy ra khi tải dữ liệu!', 'error');
			}
		},

		getGradeHistoryCacheKey(studentId, cotDiemId) {
			const filter = this.filter;
			return [
				this.vueData.NienKhoa,
				filter.LopItem?.LopID,
				filter.MonHocItem?.MonHocID,
				cotDiemId,
				studentId
			].join('|');
		},

		// Log_Diem chỉ trả các bản ghi từ bảng log; có ít nhất một dòng nghĩa là ô điểm từng được chỉnh sửa.
		hasGradeHistory(rows) {
			return Array.isArray(rows) && rows.length > 0;
		},

		// Dùng pseudo-element cho icon để marker nằm trên màu nền nhưng không sửa nội dung ô công thức
		// hoặc che tam giác comment đỏ ở góc trên bên phải.
		markGradeHistoryCell(studentId, maCotDiem) {
			const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
			if (!sheet || typeof sheet.getValueFromCoords !== 'function') return;

			const studentIdColumnIndex = this.headers.findIndex(item => item.name === 'HocSinhID');
			const gradeColumnIndex = this.headers.findIndex(item => item.name === maCotDiem);
			if (studentIdColumnIndex < 0 || gradeColumnIndex < 0 || typeof sheet.getData !== 'function') return;

			const rows = sheet.getData();
			const rowIndex = rows.findIndex((_, index) =>
				String(sheet.getValueFromCoords(studentIdColumnIndex, index)) === String(studentId)
			);
			const spreadsheetApi = typeof jspreadsheet !== 'undefined' ? jspreadsheet : null;
			if (rowIndex < 0 || !spreadsheetApi?.helpers?.getCellNameFromCoords) return;

			const cellAddress = spreadsheetApi.helpers.getCellNameFromCoords(gradeColumnIndex, rowIndex);
			const cell = typeof sheet.getCell === 'function'
				? sheet.getCell(cellAddress)
				: (typeof sheet.getCellFromCoords === 'function'
					? sheet.getCellFromCoords(gradeColumnIndex, rowIndex)
					: null);
			if (cell?.classList) cell.classList.add('grade-history-cell');
		},

		async loadGradeHistoryMarkers(students, apiData, requestId) {
			const filter = this.filter;
			if (!Array.isArray(students) || students.length === 0) return;

			try {
				// SP nhận HocSinhID tùy chọn: bỏ tham số để lấy log cả lớp trong một request; HocSinhID vẫn dùng được cho màn hình cần tra từng em.
				const response = await BangDiemService.api.getLogDiem({
					NienKhoa: this.vueData.NienKhoa,
					LopID: filter.LopItem?.LopID,
					MonHocID: filter.MonHocItem?.MonHocID,
					MaNhomCotDiem: filter.MaNhomCotDiemItem?.MaNhomCotDiem
				});
				if (requestId !== this.gradeHistoryLoadId) return;

				const logRows = Array.isArray(response)
					? response
					: (Array.isArray(response?.Result) ? response.Result : []);
				const logsByStudent = new Map();
				logRows.forEach(log => {
					const studentKey = String(log.HocSinhID);
					if (!logsByStudent.has(studentKey)) logsByStudent.set(studentKey, []);
					logsByStudent.get(studentKey).push(log);
				});

				const apiCellsByStudent = new Map();
				apiData.forEach(apiCell => {
					const studentKey = String(apiCell.HocSinhID);
					if (!apiCellsByStudent.has(studentKey)) apiCellsByStudent.set(studentKey, []);
					apiCellsByStudent.get(studentKey).push(apiCell);
				});

				students.forEach(student => {
					const studentLogs = logsByStudent.get(String(student.HocSinhID)) || [];
					const logsByColumn = studentLogs.reduce((map, log) => {
						const key = String(log.CotDiemID);
						if (!map[key]) map[key] = [];
						map[key].push(log);
						return map;
					}, {});

					(apiCellsByStudent.get(String(student.HocSinhID)) || []).forEach(apiCell => {
						const rows = (logsByColumn[String(apiCell.CotDiemID)] || [])
							.sort((left, right) => this.getHistoryTimeValue(right) - this.getHistoryTimeValue(left));
						const cacheKey = this.getGradeHistoryCacheKey(student.HocSinhID, apiCell.CotDiemID);
						this.gradeHistoryCache[cacheKey] = rows;

						// API chỉ trả lịch sử; không còn trộn dòng điểm hiện tại nên một log là đủ bật icon.
						if (this.hasGradeHistory(rows)) {
							this.markGradeHistoryCell(student.HocSinhID, apiCell.MaCotDiem);
						}
					});
				});
			} catch (error) {
				if (requestId === this.gradeHistoryLoadId) console.warn('loadGradeHistoryMarkers error:', error);
			}
		},

		// JSpreadsheet gọi callback này khi người dùng mở context menu trên một ô.
		// Chỉ giữ mục lịch sử; các lệnh mặc định như Copy/Delete/Paste/Edit comments không phù hợp với bảng nhập điểm.
		onGradeContextMenu(instance, x, y, event) {
			const columnIndex = Number(x);
			const rowIndex = Number(y);
			const header = this.headers[columnIndex];
			const sheet = Array.isArray(instance) ? instance[0] : instance;
			const studentIdColumnIndex = this.headers.findIndex(item => item.name === 'HocSinhID');
			const studentId = studentIdColumnIndex >= 0 && typeof sheet?.getValueFromCoords === 'function'
				? sheet.getValueFromCoords(studentIdColumnIndex, rowIndex)
				: this.DSHocSinh[rowIndex]?.HocSinhID;
			const student = this.DSHocSinh.find(item => String(item.HocSinhID) === String(studentId));

			if (!header?.name || !student?.HocSinhID || columnIndex < this.freezeColumns) {
				return [];
			}

			const apiCell = this.DSHocSinh_API.find(item =>
				String(item.HocSinhID) === String(student.HocSinhID) && item.MaCotDiem === header.name
			);

			if (!apiCell) return [];

			return [{
				title: this.isEn ? 'View grade history' : 'Xem lịch sử điểm',
				onclick: () => this.openGradeHistory(student, header, apiCell)
			}];
		},

		// Tải log theo đúng học sinh + cột điểm, sau đó cache để các lần chuột phải tiếp theo không gọi API lặp lại.
		async openGradeHistory(student, header, apiCell) {
			const filter = this.filter;
			const dialog = this.action.gradeHistoryDialog;
			const cacheKey = this.getGradeHistoryCacheKey(student.HocSinhID, apiCell.CotDiemID);

			dialog.studentName = student.HoVaTenHocSinh || student.HocSinhID;
			dialog.studentId = student.HocSinhID || '';
			dialog.columnTitle = header.displayTitle || header.title || header.name;
			dialog.error = '';
			dialog.rows = [];
			dialog.show = true;

			if (Object.prototype.hasOwnProperty.call(this.gradeHistoryCache, cacheKey)) {
				this.ensureTeacherNameMap();
				dialog.rows = this.gradeHistoryCache[cacheKey];
				if (this.hasGradeHistory(dialog.rows)) {
					this.markGradeHistoryCell(student.HocSinhID, header.name);
				}
				return;
			}

			dialog.loading = true;
			try {
				const response = await BangDiemService.api.getLogDiem({
					NienKhoa: this.vueData.NienKhoa,
					LopID: filter.LopItem?.LopID,
					MonHocID: filter.MonHocItem?.MonHocID,
					MaNhomCotDiem: filter.MaNhomCotDiemItem?.MaNhomCotDiem,
					HocSinhID: student.HocSinhID
				});
				const logRows = Array.isArray(response)
					? response
					: (Array.isArray(response?.Result) ? response.Result : []);
				const rows = logRows
					.filter(log => String(log.CotDiemID) === String(apiCell.CotDiemID))
					.sort((left, right) => this.getHistoryTimeValue(right) - this.getHistoryTimeValue(left));

				this.gradeHistoryCache[cacheKey] = rows;
				// Tải tên giáo viên sau khi có log; nếu endpoint danh mục lỗi thì vẫn giữ mã nhân viên làm fallback.
				await this.ensureTeacherNameMap();
				dialog.rows = rows;
				// Truy vấn theo đúng học sinh là fallback để vẫn đánh dấu cell nếu lần nạp log toàn lớp bỏ sót cột công thức.
				if (this.hasGradeHistory(rows)) {
					this.markGradeHistoryCell(student.HocSinhID, header.name);
				}
			} catch (error) {
				console.error('openGradeHistory error:', error);
				dialog.error = this.isEn ? 'Unable to load grade history.' : 'Không thể tải lịch sử điểm.';
			} finally {
				dialog.loading = false;
			}
		},

			getHistoryTimeValue(log) {
				const raw = String(log?.NhapDiemTime || log?.UpdateTime || log?.CreateTime || '');
				// API trả thêm mili-giây để các lần cập nhật sát nhau vẫn được sắp xếp đúng thứ tự.
				const match = raw.match(/^(\d{2})\/(\d{2})\/(\d{4})(?:\s+(\d{2}):(\d{2}):(\d{2})(?:\.(\d{1,3}))?)?/);
				if (match) {
					const baseTime = new Date(`${match[3]}-${match[2]}-${match[1]}T${match[4] || '00'}:${match[5] || '00'}:${match[6] || '00'}`).getTime();
					const milliseconds = Number(String(match[7] || '').padEnd(3, '0')) || 0;
					return baseTime + milliseconds;
				}
				return Date.parse(raw) || 0;
			},

			async ensureTeacherNameMap() {
				if (this.teacherNameMapLoaded) return this.teacherNameMap;
				if (this.teacherNameMapLoading) return await this.teacherNameMapLoading;

				this.teacherNameMapLoading = BangDiemService.api.getTeacherList()
					.then(response => {
						const teachers = Array.isArray(response)
							? response
							: (Array.isArray(response?.Result) ? response.Result : []);
						this.teacherNameMap = teachers.reduce((map, teacher) => {
							const teacherId = String(teacher?.GiaoVienID || '').trim();
							const teacherName = String(teacher?.HoTenGV || '').trim();
							if (teacherId && teacherName) map[teacherId] = teacherName;
							return map;
						}, {});
						this.teacherNameMapLoaded = true;
						this.teacherNameMapLoading = null;
						return this.teacherNameMap;
					})
					.catch(error => {
						console.warn('ensureTeacherNameMap error:', error);
						this.teacherNameMapLoading = null;
						return this.teacherNameMap;
					});

				return await this.teacherNameMapLoading;
			},

			getHistoryUserLabel(log) {
				const userId = String(log?.NhapDiemUser || log?.UpdateUser || log?.CreateUser || '').trim();
				if (!userId) return '-';
				const teacherName = this.teacherNameMap[userId];
				return teacherName ? teacherName + ' (' + userId + ')' : userId;
			},

			onChangeSheet(options) {
			setTimeout(() => { this.processChange(options); }, 0);
		},

		processChange({ instance, cell, x, y, value }) {
			const existingIndex = this.editedCells.findIndex(c => c.x == x && c.y == y);
			if (existingIndex === -1) {
				this.editedCells = [...this.editedCells, { x, y, cellName: instance.getValueFromCoords(x, y), value }];
			} else {
				const updated = [...this.editedCells];
				updated[existingIndex] = { ...updated[existingIndex], value };
				this.editedCells = updated;
			}
			// Giữ nguyên cảnh báo theo snapshot lúc tải; chỉ làm mới giá trị công thức sẽ gửi khi lưu.
			this.refreshFormulaMismatchSaveValues();
		},

		clearFormulaMismatchMarkers() {
			const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
			Object.entries(this.formulaMismatchOriginalStyles).forEach(([address, original]) => {
				if (typeof sheet?.setStyle === 'function') {
					sheet.setStyle(address, 'background-color', original.backgroundColor);
				}
				const cell = typeof sheet?.getCell === 'function' ? sheet.getCell(address) : null;
				if (!cell) return;
				cell.style.backgroundColor = original.backgroundColor || '';
				if (original.title == null) cell.removeAttribute('title');
				else cell.setAttribute('title', original.title);
			});
			this.formulaMismatchOriginalStyles = {};
			this.formulaMismatchCells = [];
		},

		// Chỉ tạo cảnh báo khi bảng vừa tải; không so sánh lại sau mỗi lần giáo viên nhập điểm.
		refreshFormulaMismatchMarkers() {
			const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
			if (!sheet || !Array.isArray(this.DSHocSinh_API) || !this.DSHocSinh_API.length) return;

			this.clearFormulaMismatchMarkers();
			const studentIdColumn = this.headers.findIndex(column => column.name === 'HocSinhID');
			if (studentIdColumn < 0 || typeof sheet.getData !== 'function') return;

			// Dùng mã học sinh trong thứ tự dữ liệu hiện tại của sheet để không lệch ô khi bảng đã sắp xếp/lọc.
			const rowIndexByStudentId = new Map();
			sheet.getData().forEach((row, rowIndex) => {
				const studentId = row?.[studentIdColumn] ?? sheet.getValueFromCoords?.(studentIdColumn, rowIndex);
				if (studentId != null) rowIndexByStudentId.set(String(studentId), rowIndex);
			});
			const columnIndexByCode = new Map(this.headers.map((column, index) => [column.name, index]));
			const mismatches = [];

			this.DSHocSinh_API.forEach(apiCell => {
				if (apiCell.LoaiCotDiem !== 'Công thức' && !apiCell.Formula) return;
				const rowIndex = rowIndexByStudentId.get(String(apiCell.HocSinhID));
				const columnIndex = columnIndexByCode.get(apiCell.MaCotDiem);
				if (rowIndex == null || columnIndex == null) return;

				const address = jspreadsheet.helpers.getCellNameFromCoords(columnIndex, rowIndex);
				const formulaCell = sheet.records?.[rowIndex]?.[columnIndex];
				const cell = formulaCell?.element || sheet.getCell?.(address);
				// Lấy innerHTML từ record khi hàng đang nằm ngoài vùng render ảo; công thức vẫn có kết quả để đối chiếu.
				const rawCalculatedValue = cell?.textContent ?? formulaCell?.innerHTML ?? '';
				const calculatedValue = String(rawCalculatedValue).replace(/<[^>]*>/g, '').trim();
				const savedValue = apiCell.KetQuaDanhGia_VI;
				if ((!cell && !formulaCell) || !calculatedValue || /^#(REF!?|DIV\/0!?|VALUE!?|NAME\?|N\/A|NUM!?|NULL!?|ERROR!?)/i.test(calculatedValue)) return;

				const savedNumber = savedValue === null || savedValue === undefined || String(savedValue).trim() === ''
					? NaN : Number(savedValue);
				const calculatedNumber = Number(calculatedValue);
				const bothNumeric = Number.isFinite(savedNumber) && Number.isFinite(calculatedNumber);
				const isDifferent = bothNumeric
					? Math.abs(savedNumber - calculatedNumber) > 0.000001
					: String(savedValue ?? '').trim() !== calculatedValue;
				if (!isDifferent) return;

				const configuredBackground = String(this.styleSheet[address] || '').match(/background-color\s*:\s*([^;]+)/i)?.[1]
					|| this.headers[columnIndex]?.backGroundColor
					|| '';
				this.formulaMismatchOriginalStyles[address] = {
					backgroundColor: cell?.style?.backgroundColor || configuredBackground,
					title: cell?.getAttribute?.('title') ?? null
				};
				// Tô màu cam để phân biệt giá trị công thức hiển thị với giá trị API đang lưu; không khóa thao tác lưu.
				if (typeof sheet.setStyle === 'function') sheet.setStyle(address, 'background-color', '#ffe0a3');
				if (cell?.style) cell.style.backgroundColor = '#ffe0a3';
				const detail = `${this.isEn ? 'Saved API value' : 'Giá trị API đã lưu'}: ${savedValue ?? '(trống)'} | ${this.isEn ? 'initial sheet value' : 'bảng tính lúc tải'}: ${calculatedValue}`;
				const originalTitle = this.formulaMismatchOriginalStyles[address].title;
				if (cell?.setAttribute) cell.setAttribute('title', originalTitle ? `${originalTitle}\n${detail}` : detail);
				mismatches.push({
					address,
					studentId: apiCell.HocSinhID,
					columnCode: apiCell.MaCotDiem,
					rowIndex,
					columnIndex,
					savedValue,
					calculatedValue
				});
			});

			this.formulaMismatchCells = mismatches;
		},

		// Giữ snapshot cảnh báo cố định, nhưng dùng kết quả công thức hiện tại khi giáo viên lưu điểm.
		refreshFormulaMismatchSaveValues() {
			const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
			if (!sheet || !this.formulaMismatchCells.length || typeof sheet.getData !== 'function') return;

			const studentIdColumn = this.headers.findIndex(column => column.name === 'HocSinhID');
			if (studentIdColumn < 0) return;

			const rowIndexByStudentId = new Map();
			sheet.getData().forEach((row, rowIndex) => {
				const studentId = row?.[studentIdColumn] ?? sheet.getValueFromCoords?.(studentIdColumn, rowIndex);
				if (studentId != null) rowIndexByStudentId.set(String(studentId), rowIndex);
			});
			const columnIndexByCode = new Map(this.headers.map((column, index) => [column.name, index]));

			this.formulaMismatchCells = this.formulaMismatchCells.map(mismatch => {
				const rowIndex = rowIndexByStudentId.get(String(mismatch.studentId));
				const columnIndex = columnIndexByCode.get(mismatch.columnCode);
				if (rowIndex == null || columnIndex == null) return mismatch;

				const formulaCell = sheet.records?.[rowIndex]?.[columnIndex];
				const cellAddress = jspreadsheet.helpers.getCellNameFromCoords(columnIndex, rowIndex);
				const cell = formulaCell?.element || sheet.getCell?.(cellAddress);
				if (!cell && !formulaCell) return mismatch;

				const rawValue = cell?.textContent ?? formulaCell?.innerHTML ?? '';
				const saveValue = String(rawValue).replace(/<[^>]*>/g, '').trim();
				return { ...mismatch, rowIndex, columnIndex, saveValue };
			});
		},

		// ============================================================
		// SAVE / SEND
		// ============================================================

		async onLuuTam() {
			try {
				const cellsToSave = this.pendingSaveCells;
				const success = await BangDiemService.saveData(
					cellsToSave, this.DSHocSinh, this.DSHocSinh_API,
					this.freezeColumns, { ...this.filter, NienKhoa: this.vueData.NienKhoa },
					this.instance, this.vueData
				);
				if (!success) return;
				await BangDiemService.saveDraft(this.filter, this.vueData);
				this.showSnackbar('Lưu dữ liệu thành công!', 'success');
				await this.onRefresh();
			} catch (error) {
				console.error('onLuuTam error:', error);
				this.showSnackbar('Có lỗi xảy ra khi lưu dữ liệu!', 'error');
			}
		},

		async onLuuTamTatCa() {
			try {
				const allCells = [];
				this.DSHocSinh.forEach((student, rowIndex) => {
					this.DSCotDiem_ByMaNhomCotDiem.forEach((cotDiem, colIndex) => {
						if (student[cotDiem.value] != null && student[cotDiem.value] !== '') {
							allCells.push({ x: colIndex + this.freezeColumns, y: rowIndex, value: student[cotDiem.value] });
						}
					});
				});
				const success = await BangDiemService.saveData(
					allCells, this.DSHocSinh, this.DSHocSinh_API,
					this.freezeColumns, { ...this.filter, NienKhoa: this.vueData.NienKhoa },
					this.instance, this.vueData
				);
				if (!success) return;
				await BangDiemService.saveDraft(this.filter, this.vueData);
				this.showSnackbar('Lưu tất cả thành công!', 'success');
				await this.onRefresh();
			} catch (error) {
				console.error('onLuuTamTatCa error:', error);
				this.showSnackbar('Có lỗi xảy ra khi lưu dữ liệu!', 'error');
			}
		},

		async onGuiBGH() {
			try {
				const cellsToSave = this.pendingSaveCells;
				const success = await BangDiemService.saveData(
					cellsToSave, this.DSHocSinh, this.DSHocSinh_API,
					this.freezeColumns, { ...this.filter, NienKhoa: this.vueData.NienKhoa },
					this.instance, this.vueData
				);
				if (!success) return;
				await BangDiemService.sendToBGH(this.filter, this.vueData);
				this.showSnackbar('Gửi BGH thành công!', 'success');
				await this.onRefresh();
			} catch (error) {
				console.error('onGuiBGH error:', error);
				this.showSnackbar('Có lỗi xảy ra khi gửi BGH!', 'error');
			}
		},

		// ============================================================
		// DIALOG & ACTIONS
		// ============================================================

		onOpenMauNhanXet() {
			this.action.isShowDialogMauNhanXet = true;
		},

		onXacNhanMauNhanXet(dshs) {
			this.DSHocSinh = dshs;
			this.keyComp++;
		},

		async onGetDiemTest() {
			try {
				const updatedStudents = await BangDiemService.utility.getThemeTestScore(this.filter, this.DSHocSinh);
				const mappingConfig = CONSTANTS.THEME_MAPPING[this.filter.MaNhomCotDiemItem.MaNhomCotDiem];

				if (mappingConfig) {
					const targetColumn = mappingConfig.target;
					const colIndex = this.headers.findIndex(h => h.name === targetColumn);
					updatedStudents.forEach((student, rowIndex) => {
						if (student[targetColumn] != null && student[targetColumn] !== '') {
							this.editedCells = [...this.editedCells, { x: colIndex, y: rowIndex, cellName: targetColumn, value: student[targetColumn] }];
						}
					});
				}

				this.DSHocSinh = updatedStudents;
				this.keyComp++;
				this.showSnackbar('Lấy điểm Test thành công!', 'success');
			} catch (error) {
				console.error('onGetDiemTest error:', error);
				this.showSnackbar('Có lỗi xảy ra!', 'error');
			}
		},

		onExportExcel() {
			try {
				const exportData = BangDiemService.export.prepareExportData(
					this.DSHocSinh, this.DSCotDiem_ByMaNhomCotDiem, this.instance, this.freezeColumns, this.filter, this.DSHocSinh_API
				);
				const fileName = `Bang_Diem_Lop_${this.filter.LopItem.TenLop}_${this.filter.MonHocItem.MonHocName}.xlsx`;
				BangDiemService.export.exportExcel(this.headers, exportData, fileName);
				this.showSnackbar('Xuất Excel thành công!', 'success');
			} catch (error) {
				console.error('onExportExcel error:', error);
				this.showSnackbar('Có lỗi xảy ra khi xuất Excel!', 'error');
			}
		},

		onOpenExportManyClassesDialog() {
			if (!this.filter.KhoiItem || !this.filter.LopItem || !this.filter.MonHocItem || !this.filter.MaNhomCotDiemItem) {
				this.showSnackbar('Vui lòng chọn đủ khối, lớp, môn học và mã nhóm trước khi xuất Excel!', 'warning');
				return;
			}
			const currentLopID = this.filter.LopItem?.LopID;
			this.action.exportDialog.selectedLopIDs = currentLopID ? [currentLopID] : [];
			this.action.exportDialog.show = true;
		},

		async onExportManyClasses() {
			const selectedLopIDs = this.action.exportDialog.selectedLopIDs || [];
			if (!selectedLopIDs.length) {
				this.showSnackbar('Vui lòng chọn ít nhất một lớp!', 'warning');
				return;
			}

			this.action.exportDialog.loading = true;
			try {
				const sheets = [];
				for (const lopID of selectedLopIDs) {
					const lopItem = this.exportableClasses.find(x => String(x.LopID) === String(lopID));
					if (!lopItem) continue;

					// Lấy thông tin MonHocItem cho lớp này để có MonHocLopID và TemplateBangDiemID chính xác
					const listMonHoc = await ajaxCALLPromise("lms/MonHoc_Get_ByLopID", {
						NienKhoa: this.vueData.NienKhoa,
						HocKi: this.vueData.NienKhoaItem.HocKi,
						LopID: lopID
					});
					const targetMonHocID = this.filter.MonHocItem?.MonHocID;
					const lopMonHocItem = listMonHoc?.find(x => x.MonHocID === targetMonHocID);
					if (!lopMonHocItem) continue;

					const exportFilter = {
						...this.filter,
						LopItem: lopItem,
						MonHocItem: lopMonHocItem
					};
					const result = await BangDiemService.initialize(exportFilter, this.vueData);
					if (!result.students?.length) continue;

					const exportData = BangDiemService.export.prepareExportData(
						result.students,
						result.DSCotDiem_ByMaNhomCotDiem,
						null,
						result.freezeColumns,
						exportFilter,
						result.apiData
					);
					sheets.push({
						name: lopItem.TenLop,
						headers: result.headers,
						data: exportData
					});
				}

				if (!sheets.length) {
					this.showSnackbar('Không có dữ liệu để xuất ở các lớp đã chọn!', 'warning');
					return;
				}

				const monName = this.filter.MonHocItem?.TenMonHoc_HienThi || this.filter.MonHocItem?.MonHocName || 'MonHoc';
				const maNhom = this.filter.MaNhomCotDiemItem?.MaNhomCotDiem || 'Nhom';
				const fileName = `Bang_Diem_${monName}_${maNhom}_${sheets.length}_Lop.xlsx`;
				BangDiemService.export.exportWorkbook(sheets, fileName);
				this.action.exportDialog.show = false;
				this.showSnackbar(`Xuất Excel ${sheets.length} lớp thành công!`, 'success');
			} catch (error) {
				console.error('onExportManyClasses error:', error);
				this.showSnackbar('Có lỗi xảy ra khi xuất Excel nhiều lớp!', 'error');
			} finally {
				this.action.exportDialog.loading = false;
			}
		},

		onExportAiWarnings() {
			try {
				if (!this.aiWarnings?.length) return;
				
				const headers = [
					'Dòng',
					'Mã học sinh',
					'Học sinh',
					'Môn/Cột điểm',
					'Loại lỗi',
					'Nhận xét hiện tại',
					'Chi tiết lỗi / Cảnh báo',
					'Nhận xét đề xuất sửa'
				];
				
				const dataRows = this.aiWarnings.map(w => {
					const errorType = w.type === 'limit' ? 'Vượt ký tự' : 'Lỗi chính tả/cú pháp';
					const details = w.type === 'limit' 
						? w.message 
						: (w.suggestions || []).join('; ');
					
					return [
						w.rowNum,
						w.studentId || '',
						w.studentName,
						w.subjectName,
						errorType,
						w.currentText,
						details,
						w.correctedText || ''
					];
				});
				
				const worksheet = XLSX.utils.aoa_to_sheet([headers, ...dataRows]);
				
				worksheet['!cols'] = [
					{ wch: 8 },   // Dòng
					{ wch: 15 },  // Mã học sinh
					{ wch: 25 },  // Học sinh
					{ wch: 20 },  // Môn
					{ wch: 15 },  // Loại lỗi
					{ wch: 45 },  // Nhận xét hiện tại
					{ wch: 50 },  // Chi tiết lỗi
					{ wch: 45 }   // Nhận xét đề xuất
				];
				
				const workbook = XLSX.utils.book_new();
				XLSX.utils.book_append_sheet(workbook, worksheet, 'Báo cáo lỗi nhận xét');
				
				const lopName = this.filter.LopItem?.TenLop || 'Lop';
				const monName = this.filter.MonHocItem?.MonHocName || 'MonHoc';
				const checkType = this.action.aiResultDialog.title?.includes('AI') ? 'AI' : 'DoDai';
				const fileName = `Bao_Cao_Loi_Nhan_Xet_${checkType}_${lopName}_${monName}.xlsx`;
				
				XLSX.writeFile(workbook, fileName);
				this.showSnackbar('Xuất file Excel báo cáo lỗi thành công!', 'success');
			} catch (error) {
				console.error('onExportAiWarnings error:', error);
				this.showSnackbar('Có lỗi xảy ra khi xuất file Excel!', 'error');
			}
		},

		parseHtmlTags(htmlString) {
			if (!htmlString) return '';
			try {
				const parser = new DOMParser();
				const doc = parser.parseFromString(`<body>${htmlString}</body>`, 'text/html');
				const root = doc.body;

				const transform = (node) => {
					if (node.nodeType === 3) { // TEXT_NODE
						const span = document.createElement('span');
						span.textContent = node.textContent;
						return span;
					}

					if (node.nodeType === 1) { // ELEMENT_NODE
						const tagName = node.tagName.toLowerCase();
						const wrapper = document.createElement('span');
						const text = node.textContent || '';
						const isSpaceOnly = text.trim() === '' && text.length > 0;

						if (tagName === 'del') {
							if (isSpaceOnly) {
								wrapper.className = 'bg-red-lighten-3 text-red-darken-4 font-weight-bold';
								wrapper.style.backgroundColor = '#ff8a80';
								wrapper.style.color = '#b71c1c';
								wrapper.style.textDecoration = 'underline';
								wrapper.style.textUnderlineOffset = '4px';
								wrapper.style.padding = '0 4px';
								wrapper.style.borderRadius = '2px';
								wrapper.innerHTML = '&nbsp;'.repeat(text.length);
							} else {
								wrapper.className = 'bg-red-lighten-4 text-red-darken-4 font-weight-bold';
								wrapper.style.backgroundColor = '#ffcdd2';
								wrapper.style.color = '#b71c1c';
								wrapper.style.textDecoration = 'line-through';
								wrapper.style.padding = '0 2px';
								wrapper.style.borderRadius = '2px';
								Array.from(node.childNodes).forEach(child => {
									wrapper.appendChild(transform(child));
								});
							}
						} else if (tagName === 'ins') {
							if (isSpaceOnly) {
								wrapper.className = 'bg-green-lighten-3 text-green-darken-4 font-weight-bold';
								wrapper.style.backgroundColor = '#b9f6ca';
								wrapper.style.color = '#1b5e20';
								wrapper.style.padding = '0 4px';
								wrapper.style.borderRadius = '2px';
								wrapper.innerHTML = '&nbsp;'.repeat(text.length);
							} else {
								wrapper.className = 'bg-green-lighten-4 text-green-darken-4 font-weight-bold';
								wrapper.style.backgroundColor = '#c8e6c9';
								wrapper.style.color = '#1b5e20';
								wrapper.style.padding = '0 2px';
								wrapper.style.borderRadius = '2px';
								Array.from(node.childNodes).forEach(child => {
									wrapper.appendChild(transform(child));
								});
							}
						} else {
							Array.from(node.childNodes).forEach(child => {
								wrapper.appendChild(transform(child));
							});
						}
						return wrapper;
					}

					return document.createTextNode('');
				};

				const container = document.createElement('div');
				Array.from(root.childNodes).forEach(child => {
					container.appendChild(transform(child));
				});
				return container.innerHTML;
			} catch (e) {
				console.error('Lỗi khi phân tích HTML bằng DOMParser:', e);
				return htmlString;
			}
		},

		getDiffMarkup(oldStr, newStr) {
			if (!oldStr) return { oldHtml: '', newHtml: '' };
			if (!newStr) return { oldHtml: oldStr, newHtml: '' };

			const dp = Array(oldStr.length + 1).fill(null).map(() => Array(newStr.length + 1).fill(0));
			for (let i = 1; i <= oldStr.length; i++) {
				for (let j = 1; j <= newStr.length; j++) {
					if (oldStr[i - 1] === newStr[j - 1]) {
						dp[i][j] = dp[i - 1][j - 1] + 1;
					} else {
						dp[i][j] = Math.max(dp[i - 1][j], dp[i][j - 1]);
					}
				}
			}

			let i = oldStr.length;
			let j = newStr.length;
			const diff = [];

			while (i > 0 || j > 0) {
				if (i > 0 && j > 0 && oldStr[i - 1] === newStr[j - 1]) {
					diff.push({ type: 'common', value: oldStr[i - 1] });
					i--;
					j--;
				} else if (j > 0 && (i === 0 || dp[i][j - 1] >= dp[i - 1][j])) {
					diff.push({ type: 'added', value: newStr[j - 1] });
					j--;
				} else {
					diff.push({ type: 'removed', value: oldStr[i - 1] });
					i--;
				}
			}
			diff.reverse();

			const escapeHtml = (str) => {
				return str
					.split('&').join('&amp;')
					.split('<').join('&lt;')
					.split('>').join('&gt;')
					.split('"').join('&quot;')
					.split("'").join('&#039;');
			};

			let oldHtml = '';
			let newHtml = '';

			diff.forEach(part => {
				const escapedValue = escapeHtml(part.value);
				if (part.type === 'common') {
					oldHtml += escapedValue;
					newHtml += escapedValue;
				} else if (part.type === 'removed') {
					if (part.value === ' ') {
						oldHtml += `<span class="bg-red-lighten-3 text-red-darken-4 font-weight-bold" style="background-color: #ff8a80; color: #b71c1c; text-decoration: underline; text-underline-offset: 4px; padding: 0 4px; border-radius: 2px;">&nbsp;</span>`;
					} else {
						oldHtml += `<span class="bg-red-lighten-4 text-red-darken-4 font-weight-bold" style="background-color: #ffcdd2; color: #b71c1c; text-decoration: line-through; padding: 0 2px; border-radius: 2px;">${escapedValue}</span>`;
					}
				} else if (part.type === 'added') {
					if (part.value === ' ') {
						newHtml += `<span class="bg-green-lighten-3 text-green-darken-4 font-weight-bold" style="background-color: #b9f6ca; color: #1b5e20; padding: 0 4px; border-radius: 2px;">&nbsp;</span>`;
					} else {
						newHtml += `<span class="bg-green-lighten-4 text-green-darken-4 font-weight-bold" style="background-color: #c8e6c9; color: #1b5e20; padding: 0 2px; border-radius: 2px;">${escapedValue}</span>`;
					}
				}
			});

			return { oldHtml, newHtml };
		},

		onCheckCommentAI() {
			if (this.isDisabled || !this.hasStudents) return;
			this.action.aiColumnDialog.selectedColumns = this.textColumns
				.filter(col => !col.isLocked)
				.map(col => col.value);
			this.action.aiColumnDialog.show = true;
		},

		onToggleAiColumn(value) {
			const col = this.textColumns.find(c => c.value === value);
			if (col?.isLocked) return;
			const idx = this.action.aiColumnDialog.selectedColumns.indexOf(value);
			if (idx === -1) {
				this.action.aiColumnDialog.selectedColumns = [...this.action.aiColumnDialog.selectedColumns, value];
			} else {
				this.action.aiColumnDialog.selectedColumns = this.action.aiColumnDialog.selectedColumns.filter(v => v !== value);
			}
		},

		onApplyAiSuggestion(warning) {
			try {
				const rowIndex = warning.rowNum - 1;
				const colIndex = this.headers.findIndex(h => h.name === warning.colValue);
				if (colIndex !== -1 && this.instance) {
					const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
					if (sheet && typeof sheet.setValueFromCoords === 'function') {
						sheet.setValueFromCoords(colIndex, rowIndex, warning.correctedText);
						warning.applied = true;
						this.showSnackbar('Đã áp dụng nhận xét sửa đổi!', 'success');
					} else {
						this.showSnackbar('Không thể áp dụng nhận xét (bảng điểm chưa sẵn sàng)!', 'warning');
					}
				} else {
					this.showSnackbar('Không tìm thấy ô điểm tương ứng trên bảng!', 'warning');
				}
			} catch (err) {
				console.error('onApplyAiSuggestion error:', err);
				this.showSnackbar('Có lỗi xảy ra khi áp dụng nhận xét.', 'error');
			}
		},

		onApplyAllAiSuggestions() {
			try {
				if (!this.aiWarnings || this.aiWarnings.length === 0) {
					this.showSnackbar('Không có gợi ý nào để áp dụng!', 'warning');
					return;
				}
				if (!this.instance) {
					this.showSnackbar('Bảng điểm chưa sẵn sàng!', 'warning');
					return;
				}
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
				if (!sheet || typeof sheet.setValueFromCoords !== 'function') {
					this.showSnackbar('Không thể áp dụng nhận xét (bảng điểm chưa sẵn sàng)!', 'warning');
					return;
				}
				let count = 0;
				this.aiWarnings.forEach(warning => {
					if (warning.type === 'spelling' && !warning.applied) {
						const rowIndex = warning.rowNum - 1;
						const colIndex = this.headers.findIndex(h => h.name === warning.colValue);
						if (colIndex !== -1) {
							sheet.setValueFromCoords(colIndex, rowIndex, warning.correctedText);
							warning.applied = true;
							count++;
						}
					}
				});
				if (count > 0) {
					this.showSnackbar(`Đã áp dụng thành công ${count} nhận xét sửa đổi!`, 'success');
				} else {
					this.showSnackbar('Không có nhận xét mới nào cần áp dụng!', 'info');
				}
			} catch (err) {
				console.error('onApplyAllAiSuggestions error:', err);
				this.showSnackbar('Có lỗi xảy ra khi áp dụng tất cả nhận xét.', 'error');
			}
		},

		onShowPreviousAiResult() {
			this.action.aiColumnDialog.show = false;
			if (this.aiWarnings && this.aiWarnings.length > 0 && this.instance) {
				const sheet = Array.isArray(this.instance) ? this.instance[0] : this.instance;
				if (sheet) {
					this.aiWarnings.forEach(warning => {
						if (warning.type === 'spelling') {
							const rowIndex = warning.rowNum - 1;
							const colIndex = this.headers.findIndex(h => h.name === warning.colValue);
							if (colIndex !== -1) {
								const currentValue = sheet.getValueFromCoords(colIndex, rowIndex) || '';
								const trimmedCurrent = currentValue.trim();
								if (trimmedCurrent === warning.correctedText.trim()) {
									warning.applied = true;
								}
							}
						}
					});
				}
			}
			this.action.aiResultDialog.title = 'Kết quả kiểm tra nhận xét bằng AI';
			this.action.aiResultDialog.show = true;
		},


		async onConfirmCheckCommentAI(forceRefresh = false) {
			this.action.aiColumnDialog.show = false;
			this.aiWarnings = [];
			this.isCheckingAI = true;

			// 1. Tải nhận xét cấp 1 liên quan nếu cần
			let allComments = [];
			const isCap1 = parseInt(this.vueData.CapID) === 1;
			const lopID = this.filter.LopItem?.LopID;
			const nienKhoa = this.vueData.NienKhoa;
			const maNhom = this.filter.MaNhomCotDiemItem?.MaNhomCotDiem || '';

			let hocKi = '';
			if (maNhom.includes('GK_HK1')) hocKi = 'GK_HK1';
			else if (maNhom.includes('CK_HK1')) hocKi = 'CK_HK1';
			else if (maNhom.includes('GK_HK2')) hocKi = 'GK_HK2';
			else if (maNhom.includes('CK_HK2')) hocKi = 'CK_HK2';

			const mapMonHocToNhom = {
				20: 'Năng lực chung', 21: 'Năng lực chung', 22: 'Năng lực chung',
				28: 'Năng lực đặc thù', 29: 'Năng lực đặc thù', 30: 'Năng lực đặc thù',
				31: 'Năng lực đặc thù', 32: 'Năng lực đặc thù', 33: 'Năng lực đặc thù',
				34: 'Năng lực đặc thù',
				23: 'Phẩm chất', 24: 'Phẩm chất', 25: 'Phẩm chất', 26: 'Phẩm chất', 27: 'Phẩm chất'
			};
			const mapMonHocToTenMon = {
				20: 'Tự chủ và tự học', 21: 'Giao tiếp và hợp tác', 22: 'Giải quyết vấn đề và sáng tạo',
				28: 'Ngôn ngữ', 29: 'Tính toán', 30: 'Khoa học', 31: 'Công nghệ', 32: 'Tin học',
				33: 'Thẩm mĩ', 34: 'Thể chất',
				23: 'Yêu nước', 24: 'Nhân ái', 25: 'Chăm chỉ', 26: 'Trung thực', 27: 'Trách nhiệm'
			};

			const monHocID = this.filter.MonHocItem?.MonHocID;
			const nhomNhanXet = mapMonHocToNhom[monHocID];
			const currentTenMon = mapMonHocToTenMon[monHocID];

			try {
				if (isCap1 && lopID && nienKhoa && hocKi && nhomNhanXet) {
					try {
						const resComments = await ajaxCALLPromise('lms/BaoCao_ThongKe_NhanXet_Cap1', {
							LopID: String(lopID),
							NienKhoa: nienKhoa,
							HocKi: hocKi
						});
						allComments = Array.isArray(resComments) ? resComments : [];
					} catch (err) {
						console.error('Lỗi khi tải nhận xét cấp 1 liên quan:', err);
					}
				}

				// 2. Thu thập và kiểm tra độ dài cục bộ / tổng nhóm
				const commentsToCheck = [];
				const localWarnings = [];

				this.DSHocSinh.forEach((student, rowIndex) => {
					this.DSCotDiem_ByMaNhomCotDiem.forEach((col) => {
						if (col.GiaTriCotDiem === 'text' && this.action.aiColumnDialog.selectedColumns.includes(col.value)) {
							const textValue = student[col.value] || '';
							const trimmedValue = textValue.trim();

							if (isCap1 && nhomNhanXet) {
								const otherComments = allComments
									.filter(x => x.HocSinhID === student.HocSinhID && x.NhomNhanXet === nhomNhanXet && x.TenMon !== currentTenMon)
									.map(x => x.NhanXet || '')
									.filter(Boolean);
								
								const otherLength = otherComments.reduce((sum, c) => sum + c.trim().length, 0);
								const totalLength = trimmedValue.length + otherLength;

								if (totalLength > 400) {
									localWarnings.push({
										rowNum: rowIndex + 1,
										studentId: student.HocSinhID,
										studentName: student.HoVaTenHocSinh,
										subjectName: col.title,
										type: 'limit',
										currentText: trimmedValue || '(Trống)',
										message: `Tổng nhận xét nhóm [${nhomNhanXet}] là ${totalLength} ký tự, vượt quá giới hạn 400 ký tự (Độ dài các môn khác cùng nhóm là ${otherLength} ký tự).`
									});
								}
							}

							if (trimmedValue) {
								const normKey = trimmedValue.normalize('NFC');
								if (!forceRefresh && this.aiCache && this.aiCache[normKey] !== undefined) {
									const cachedResult = this.aiCache[normKey];
									if (cachedResult.hasError) {
										if (!cachedResult.currentHtml || !cachedResult.correctedHtml) {
											const diff = this.getDiffMarkup(trimmedValue, cachedResult.correctedText || '');
											cachedResult.currentHtml = diff.oldHtml;
											cachedResult.correctedHtml = diff.newHtml;
										}
										localWarnings.push({
											rowNum: rowIndex + 1,
											colValue: col.value,
											studentId: student.HocSinhID,
											studentName: student.HoVaTenHocSinh,
											subjectName: col.title,
											type: 'spelling',
											currentText: trimmedValue,
											currentHtml: cachedResult.currentHtml,
											correctedHtml: cachedResult.correctedHtml,
											suggestions: cachedResult.suggestions || [],
											correctedText: cachedResult.correctedText || ''
										});
									}
								} else {
									commentsToCheck.push({
										id: `${rowIndex}_${col.value}`,
										text: trimmedValue,
										studentName: student.HoVaTenHocSinh,
										subjectTitle: col.title,
										colValue: col.value
									});
								}
							}
						}
					});
				});

				this.aiWarnings = [...localWarnings];

				// 3. Gửi AI kiểm tra chính tả/khoảng trắng
				if (commentsToCheck.length > 0) {
					const response = await ajaxCALLPromise('lms/auth/CallGeminiAPI', {
						Prompt: `
						Bạn là một trợ lý AI chuyên phát hiện lỗi chính tả, khoảng trắng thừa, dấu câu và lỗi cú pháp tiếng Việt trong nhận xét của học sinh. Bạn sẽ nhận được đầu vào là một mảng JSON gồm các đối tượng có dạng { "id": "tọa độ", "text": "nhận xét" }.

Nhiệm vụ của bạn:
1. Phân tích chuỗi nhận xét trong trường "text" để phát hiện các lỗi chính tả, khoảng trắng không đều, thiếu dấu câu hoặc viết hoa tùy tiện.

2. Quy tắc bắt buộc về Tổ hợp Vần (Chuẩn đặt dấu thanh cũ - Hoà / Quý):
  - Hệ thống quy định bắt buộc dùng kiểu đặt dấu cũ (dấu trên 'o' và 'u'). Gặp kiểu dấu mới (dấu trên 'a' và 'y') phải coi là LỖI CHÍNH TẢ và bắt buộc phải sửa đổi.
  - Danh sách sửa đổi bắt buộc cho nhóm vần OA/UY/OE/UÊ/UYA:
    + "òa, óa, ỏa, õa, họa" phải sửa thành "oà, oá, oả, oã, hoạ" (dấu đặt trên o).
    + "uỳ, uý, uỷ, uỹ, uỵ" phải sửa thành "ùy, úy, ủy, ũy, ụy" (dấu đặt trên u).
    + "òe, óe, ỏe, õe, ọe" phải sửa thành "oè, oé, oẻ, oẽ, oẹ" (dấu đặt trên o).
    + "uề, uế, uể, uễ, uệ" phải sửa thành "ùe, úe, ủe, ũe, ụe" (dấu đặt trên u).
  - Đồng thời, phát hiện các lỗi đặt dấu sai cấu trúc vần nghiêm trọng khác như: "hoạitử" -> "hoại tử", "húong" -> "hướng", "tìen" -> "tiền".
  - Không báo lỗi nếu sự khác biệt chỉ ở mức encoding Unicode nội bộ (NFD/NFC) mà không ảnh hưởng đến hiển thị hay nghĩa của văn bản. Chỉ báo lỗi khi sự sai khác có thể nhìn thấy bằng mắt thường.

3. Trả về kết quả dưới dạng một mảng JSON chứa các đối tượng có cấu trúc chính xác như sau:
  - "id": giữ nguyên id nhận vào.
  - "hasError": true nếu phát hiện lỗi (bao gồm lỗi đặt dấu kiểu mới như òa, úy), false nếu nhận xét hoàn toàn chính xác.
  - "suggestions": danh sách các chuỗi mô tả lỗi phát hiện được (ví dụ: ["Sai chính tả: hòa -> hoà", "Sai chính tả: quý -> qúy", "Khoảng trắng thừa: học  tốt -> học tốt"]). Nếu không có lỗi, đặt là mảng rỗng.
  - "correctedText": chuỗi nhận xét đầy đủ sau khi đã sửa toàn bộ các lỗi trên theo đúng chuẩn bắt buộc (hoà, qúy). Nếu không có lỗi, giữ nguyên nguyên văn chuỗi "text" đầu vào.
  - "currentHtml": chuỗi nhận xét gốc "text" ban đầu nhưng những ký tự/khoảng trắng bị sai hoặc thừa được bọc trong cặp thẻ <del>...</del> (ví dụ: nếu sai chữ "hòa" thì bọc <del>hòa</del>). Nếu không có lỗi, giữ nguyên nguyên văn chuỗi "text" đầu vào.
  - "correctedHtml": chuỗi nhận xét đã sửa "correctedText" nhưng những ký tự/khoảng trắng được thêm mới hoặc sửa đổi được bọc trong cặp thẻ <ins>...</ins> (ví dụ: sửa thành "hoà" thì bọc <ins>hoà</ins>). Nếu không có lỗi, giữ nguyên nguyên văn chuỗi "text" đầu vào.

Tuyệt đối không thêm bớt trường, không giải thích hay trả về bất kỳ văn bản nào khác ngoài mảng JSON đó. Không viết hoa/xuống dòng dư thừa làm hỏng định dạng JSON.

						`,
						Content: JSON.stringify(commentsToCheck.map(c => ({ id: c.id, text: c.text })))
					});

					const resultData = Array.isArray(response) ? response[0] : response;
					if (resultData && resultData.Status === 'OK') {
						let cleanText = resultData.CleanResponse;
						if (!cleanText && resultData.RawResponse) {
							try {
								const rawObj = JSON.parse(resultData.RawResponse);
								const parts = rawObj.candidates?.[0]?.content?.parts;
								if (Array.isArray(parts)) {
									for (let i = parts.length - 1; i >= 0; i--) {
										const txt = parts[i]?.text;
										if (txt && txt.trim()) {
											cleanText = txt;
											break;
										}
									}
								}
							} catch (e) {
								console.error('Lỗi khi phân tách RawResponse:', e);
							}
						}

						if (cleanText) {
							cleanText = cleanText.split('```json').join('').split('```').join('').trim();
							const correctedComments = JSON.parse(cleanText);

							if (Array.isArray(correctedComments)) {
								correctedComments.forEach(item => {
									const colInfo = commentsToCheck.find(c => c.id === item.id);
									
									// Chuẩn hóa Unicode NFC để bỏ qua các sai khác vô hình về mặt mã hóa (ví dụ: cần vs cần)
									const rawText = colInfo ? colInfo.text : '';
									const corrText = item.correctedText || '';
									if (rawText.normalize('NFC') === corrText.normalize('NFC')) {
										item.hasError = false;
									}

									let currentHtmlParsed = '';
									let correctedHtmlParsed = '';

									if (item.currentHtml && item.correctedHtml) {
										currentHtmlParsed = this.parseHtmlTags(item.currentHtml);
										correctedHtmlParsed = this.parseHtmlTags(item.correctedHtml);
									} else {
										// Fallback: nếu AI không trả về tag (hoặc do cache server cũ), client tự chạy thuật toán so sánh làm nổi bật
										const diff = this.getDiffMarkup(colInfo ? colInfo.text : '', item.correctedText || '');
										currentHtmlParsed = diff.oldHtml;
										correctedHtmlParsed = diff.newHtml;
									}

									if (colInfo) {
										if (!this.aiCache) {
											this.aiCache = {};
										}
										const normKey = colInfo.text.normalize('NFC');
										this.aiCache[normKey] = {
											hasError: !!item.hasError,
											suggestions: item.suggestions || [],
											correctedText: item.correctedText || '',
											currentHtml: currentHtmlParsed,
											correctedHtml: correctedHtmlParsed
										};
									}

									if (item.hasError) {
										const parts = item.id.split('_');
										const rowIndex = parseInt(parts[0]);
										const colName = parts[1];
										const student = this.DSHocSinh[rowIndex];

										this.aiWarnings.push({
											rowNum: rowIndex + 1,
											colValue: colInfo ? colInfo.colValue : '',
											studentId: student ? student.HocSinhID : '',
											studentName: student ? student.HoVaTenHocSinh : 'Học sinh',
											subjectName: colInfo ? colInfo.subjectTitle : 'Môn',
											type: 'spelling',
											currentText: colInfo ? colInfo.text : '',
											currentHtml: currentHtmlParsed,
											correctedHtml: correctedHtmlParsed,
											suggestions: item.suggestions || [],
											correctedText: item.correctedText || ''
										});
									}
								});
							}
						}
					} else {
						const errMsg = resultData?.ErrorMessage || 'Lỗi gọi hệ thống AI';
						this.showSnackbar(errMsg, 'error');
						return;
					}

					// Tăng số lần chạy cho các cột được chọn có gọi API
					const newCounts = { ...this.aiRunCounts };
					this.action.aiColumnDialog.selectedColumns.forEach(colVal => {
						newCounts[colVal] = (newCounts[colVal] || 0) + 1;
					});
					this.aiRunCounts = newCounts;
				}

				// Sắp xếp cảnh báo theo số dòng tăng dần
				this.aiWarnings.sort((a, b) => a.rowNum - b.rowNum);
				
				// Hiển thị dialog kết quả
				this.action.aiResultDialog.title = 'Kết quả kiểm tra nhận xét bằng AI';
				this.action.aiResultDialog.show = true;
			} catch (error) {
				console.error('onCheckCommentAI error:', error);
				this.showSnackbar('Có lỗi xảy ra khi gọi AI kiểm tra nhận xét.', 'error');
			} finally {
				this.isCheckingAI = false;
			}
		},

		async onCheckCommentLength() {
			if (this.isDisabled || !this.hasStudents) return;

			this.aiWarnings = [];
			this.showOnlyLimitExceeded = false;

			const isCap1 = parseInt(this.vueData.CapID) === 1;
			const lopID = this.filter.LopItem?.LopID;
			const nienKhoa = this.vueData.NienKhoa;
			const maNhom = this.filter.MaNhomCotDiemItem?.MaNhomCotDiem || '';

			if (!isCap1 || !lopID) {
				this.showSnackbar('Tính năng này chỉ hỗ trợ kiểm tra nhận xét cho học sinh Tiểu học (Cấp 1).', 'warning');
				return;
			}

			let hocKi = '';
			if (maNhom.includes('GK_HK1')) hocKi = 'GK_HK1';
			else if (maNhom.includes('CK_HK1')) hocKi = 'CK_HK1';
			else if (maNhom.includes('GK_HK2')) hocKi = 'GK_HK2';
			else if (maNhom.includes('CK_HK2')) hocKi = 'CK_HK2';

			const mapMonHocToNhom = {
				20: 'Năng lực chung', 21: 'Năng lực chung', 22: 'Năng lực chung',
				28: 'Năng lực đặc thù', 29: 'Năng lực đặc thù', 30: 'Năng lực đặc thù',
				31: 'Năng lực đặc thù', 32: 'Năng lực đặc thù', 33: 'Năng lực đặc thù',
				34: 'Năng lực đặc thù',
				23: 'Phẩm chất', 24: 'Phẩm chất', 25: 'Phẩm chất', 26: 'Phẩm chất', 27: 'Phẩm chất'
			};
			const mapMonHocToTenMon = {
				20: 'Tự chủ và tự học', 21: 'Giao tiếp và hợp tác', 22: 'Giải quyết vấn đề và sáng tạo',
				28: 'Ngôn ngữ', 29: 'Tính toán', 30: 'Khoa học', 31: 'Công nghệ', 32: 'Tin học',
				33: 'Thẩm mĩ', 34: 'Thể chất',
				23: 'Yêu nước', 24: 'Nhân ái', 25: 'Chăm chỉ', 26: 'Trung thực', 27: 'Trách nhiệm'
			};

			const monHocID = this.filter.MonHocItem?.MonHocID;
			const nhomNhanXet = mapMonHocToNhom[monHocID];
			const currentTenMon = mapMonHocToTenMon[monHocID];

			if (!nhomNhanXet) {
				this.showSnackbar('Tính năng này chỉ áp dụng cho các môn Năng lực hoặc Phẩm chất.', 'warning');
				return;
			}

			this.isCheckingLength = true;
			try {
				let allComments = [];
				if (lopID && nienKhoa && hocKi) {
					try {
						const resComments = await ajaxCALLPromise('lms/BaoCao_ThongKe_NhanXet_Cap1', {
							LopID: String(lopID),
							NienKhoa: nienKhoa,
							HocKi: hocKi
						});
						allComments = Array.isArray(resComments) ? resComments : [];
					} catch (err) {
						console.error('Lỗi khi tải nhận xét cấp 1 liên quan:', err);
					}
				}

				const localWarnings = [];

				this.DSHocSinh.forEach((student, rowIndex) => {
					this.DSCotDiem_ByMaNhomCotDiem.forEach((col) => {
						if (col.GiaTriCotDiem === 'text') {
							const textValue = student[col.value] || '';
							const trimmedValue = textValue.trim();

							const otherComments = allComments
								.filter(x => x.HocSinhID === student.HocSinhID && x.NhomNhanXet === nhomNhanXet && x.TenMon !== currentTenMon)
								.map(x => x.NhanXet || '')
								.filter(Boolean);
							
							const otherLength = otherComments.reduce((sum, c) => sum + c.trim().length, 0);
							const totalLength = trimmedValue.length + otherLength;

							if (totalLength > 400) {
								localWarnings.push({
									rowNum: rowIndex + 1,
									studentId: student.HocSinhID,
									studentName: student.HoVaTenHocSinh,
									subjectName: col.title,
									type: 'limit',
									currentText: trimmedValue || '(Trống)',
									message: `Tổng nhận xét nhóm [${nhomNhanXet}] là ${totalLength} ký tự, vượt quá giới hạn 400 ký tự (Độ dài các môn khác cùng nhóm là ${otherLength} ký tự).`
								});
							} else if (totalLength > 0) {
								localWarnings.push({
									rowNum: rowIndex + 1,
									studentId: student.HocSinhID,
									studentName: student.HoVaTenHocSinh,
									subjectName: col.title,
									type: 'limit_ok',
									remainingCount: 400 - totalLength,
									currentText: trimmedValue || '(Trống)',
									message: `Tổng nhận xét nhóm [${nhomNhanXet}] hiện tại là ${totalLength}/400 ký tự. Còn lại ${400 - totalLength} ký tự (Các môn khác cùng nhóm đã chiếm ${otherLength} ký tự).`
								});
							}
						}
					});
				});

				this.aiWarnings = localWarnings;
				this.action.aiResultDialog.title = 'Kết quả kiểm tra giới hạn ký tự';
				this.action.aiResultDialog.show = true;
			} catch (error) {
				console.error('onCheckCommentLength error:', error);
				this.showSnackbar('Có lỗi xảy ra khi kiểm tra độ dài nhận xét.', 'error');
			} finally {
				this.isCheckingLength = false;
			}
		}
	}
	}
</script>
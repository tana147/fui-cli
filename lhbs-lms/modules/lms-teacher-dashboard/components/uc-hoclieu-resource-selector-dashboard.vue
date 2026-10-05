<template>
	<div>
		<v-btn v-if="!isPanelOpen" block variant="tonal" color="primary" class="mb-3" @click="isPanelOpen = true">
			<v-icon start>mdi-file-tree-outline</v-icon>
			{{ $i18n.locale === 'en' ? 'Link digital curriculum (textbook)' : 'Gắn vào học liệu số (SGK)' }}
			<v-chip v-if="isLinked" size="x-small" color="success" variant="flat" class="ms-2">{{ $i18n.locale === 'en' ? 'Linked' : 'Đã gắn' }}</v-chip>
		</v-btn>
		<v-card v-else variant="tonal" color="primary" class="pa-3 mb-3">
			<div class="d-flex align-center ga-2 mb-2">
				<v-icon size="small">mdi-file-tree-outline</v-icon>
				<span class="text-subtitle-2 font-weight-medium">{{ $i18n.locale === 'en' ? 'Link digital curriculum (textbook)' : 'Gắn vào học liệu số (SGK)' }}</span>
				<v-spacer />
				<v-chip v-if="isLinked" size="x-small" color="success" variant="flat">{{ $i18n.locale === 'en' ? 'Linked' : 'Đã gắn' }}</v-chip>
				<v-btn icon="mdi-close" size="x-small" variant="text" :aria-label="$i18n.locale === 'en' ? 'Close digital curriculum' : 'Đóng học liệu số'" @click="isPanelOpen = false" />
			</div>
			<!-- Mô tả rõ mục đích: Chọn Bài/Chương trong SGK để lưu vết cấu trúc và tái sử dụng cho các năm sau -->
			<div class="text-caption text-medium-emphasis mb-2">{{ $i18n.locale === 'en' ? 'Select a Lesson or Chapter in the textbook to save and easily reuse for future school years.' : 'Chọn Bài hoặc Chương trong Sách giáo khoa để lưu bài và dễ dàng sử dụng lại cho các năm học sau.' }}</div>
			<v-select v-model="selectedHocLieuID" :items="hocLieuItems" item-title="TenHocLieu" item-value="HocLieuID"
				:label="$i18n.locale === 'en' ? 'Select digital curriculum / textbook' : 'Chọn học liệu số (SGK)'" clearable density="compact" variant="outlined" :loading="isLoadingHocLieu"
				:disabled="!khoiId || !monHocId" hide-details="auto" />
			<div v-if="selectedHocLieuID" class="mt-2">
				<div class="text-caption font-weight-medium mb-1">{{ $i18n.locale === 'en' ? 'Select Lesson / Chapter in textbook structure' : 'Chọn Bài hoặc Chương tương ứng trong SGK' }}</div>
				<v-treeview v-if="!isLoadingTree && treeNodes.length" v-model:activated="activeTreeNodeIDs"
					v-model:opened="openedTreeNodeIDs" :items="treeNodes"
					item-title="TenNoiDung" item-value="NoiDungID" item-children="children" density="compact"
					activatable color="primary" class="border rounded pa-2" style="max-height: 360px; overflow-y: auto">
					<template v-slot:prepend="{ item }">
						<v-checkbox-btn :model-value="isNodeSelected(item)"
							@click.stop="toggleNodeSelection(item)" color="primary" />
					</template>
				</v-treeview>
				<div v-else-if="isLoadingTree" class="text-caption text-medium-emphasis pa-2">{{ $i18n.locale === 'en' ? 'Loading structure...' : 'Đang tải cấu trúc học liệu...' }}</div>
			</div>
			<div v-if="selectedHocLieuID && !nodeItems.length && !isLoadingTree" class="text-caption text-warning mt-1">
				{{ $i18n.locale === 'en' ? 'This curriculum has no Chapter, Lesson or Skill Group to link.' : 'Học liệu này chưa có Chương, Bài hoặc Nhóm kỹ năng để liên kết.' }}
			</div>
		</v-card>
	</div>
</template>

<script>
	export default {
		props: {
		modelValue: { type: Object, default: function () { return {} } },
		khoiId: { type: [Number, String], default: null },
		monHocId: { type: [Number, String], default: null },
		resourceType: { type: String, default: 'LESSON' },
		resourceId: { type: [Number, String], default: 0 },
	},
	emits: ['update:modelValue'],
	data() {
		return {
			hocLieuItems: [],
			nodeItems: [],
			treeNodes: [],
			openedTreeNodeIDs: [],
			activeTreeNodeIDs: [],
			selectedHocLieuID: null,
			selectedNoiDungID: null,
			selectedNoiDungIDs: [],
			// Mặc định đóng, khi giáo viên bấm nút mới mở ra.
			isPanelOpen: false,
			isLoadingHocLieu: false,
			isLoadingTree: false,
		}
	},
	computed: {
		isLinked() {
			return !!(this.selectedHocLieuID && this.selectedNoiDungID)
		},
	},
	watch: {
		khoiId() { this.loadHocLieu() },
		monHocId() { this.loadHocLieu() },
		resourceId() { this.loadMapping() },
		activeTreeNodeIDs(values) {
			const selectedID = values?.[0] || null
			if (selectedID && this.isLinkableNode(this.nodeItems.find(node => String(node.NoiDungID) === String(selectedID)))) {
				this.selectedNoiDungID = selectedID
			}
		},
		selectedHocLieuID(newValue) {
			if (!this._isRestoringMapping) {
				this.selectedNoiDungID = null
				this.selectedNoiDungIDs = []
				this.activeTreeNodeIDs = []
				this.nodeItems = []
				this.treeNodes = []
				this.openedTreeNodeIDs = []
			}
			if (newValue) this.loadTree(newValue)
			this.emitValue()
		},
		selectedNoiDungID() { this.emitValue() },
	},
	mounted() {
		this.loadHocLieu()
		this.loadMapping()
	},
	methods: {
		rows(response) {
			const value = response?.data ?? response ?? []
			if (Array.isArray(value?.[1])) return value[1]
			return Array.isArray(value) ? value : [value]
		},
		loadHocLieu() {
			if (!this.khoiId || !this.monHocId) {
				this.hocLieuItems = []
				return
			}
			this.isLoadingHocLieu = true
			ajaxCALL('lms/FP_HocLieu_GetByLopMon', { KhoiID: this.khoiId, MonHocID: this.monHocId }, response => {
				this.hocLieuItems = this.rows(response)
				this.isLoadingHocLieu = false
				// Bài chưa có liên kết: chỉ tự chọn khi không có khả năng chọn nhầm.
				if (!this.selectedHocLieuID && this.hocLieuItems.length === 1) {
					this.selectedHocLieuID = this.hocLieuItems[0].HocLieuID
				}
			})
		},
		loadMapping() {
			if (!this.resourceId || Number(this.resourceId) <= 0) return
			ajaxCALL('lms/EL_HocLieuResource_Get', { ResourceType: this.resourceType, ResourceID: this.resourceId }, response => {
				const item = this.rows(response)[0]
				if (!item) return
				const mappedNodeID = item.NoiDungID
				this._isRestoringMapping = true
				this.selectedHocLieuID = item.HocLieuID
				this.isPanelOpen = true
				this.$nextTick(() => {
					this.selectedNoiDungID = mappedNodeID
					this.selectedNoiDungIDs = [String(mappedNodeID)]
					this.activeTreeNodeIDs = [mappedNodeID]
					this._isRestoringMapping = false
					if (this.selectedHocLieuID) this.loadTree(this.selectedHocLieuID)
				})
			})
		},
		loadTree(hocLieuID) {
			this.isLoadingTree = true
			ajaxCALL('lms/FP_NoiDung_GetTreeByHocLieu', { HocLieuID: hocLieuID }, response => {
				const allNodes = this.rows(response)
				const linkableNodes = allNodes.filter(node => this.isLinkableNode(node))
				this.nodeItems = this.flattenNodes(linkableNodes)
				this.treeNodes = this.buildTree(linkableNodes)
				this.openedTreeNodeIDs = []
				this.isLoadingTree = false
				
				// Tự động kiểm tra và chuẩn hóa NoiDungID nếu dữ liệu cũ từng trỏ tới node con không hợp lệ
				if (this.selectedNoiDungID) {
					let targetNode = this.nodeItems.find(n => String(n.NoiDungID) === String(this.selectedNoiDungID))
					if (!targetNode) {
						// Leo lên cây để tìm node cha hợp lệ gần nhất (BAI hoặc CHUONG)
						let rawNode = allNodes.find(n => String(n.NoiDungID) === String(this.selectedNoiDungID))
						while (rawNode && rawNode.ParentID) {
							const parent = allNodes.find(n => String(n.NoiDungID) === String(rawNode.ParentID))
							if (parent && this.isLinkableNode(parent)) {
								targetNode = parent
								this.selectedNoiDungID = targetNode.NoiDungID
								this.emitValue()
								break
							}
							rawNode = parent
						}
					}
					if (targetNode) {
						const familyIDs = this.getAllNodeAndDescendantIDs(targetNode)
						this.selectedNoiDungIDs = familyIDs
						this.activeTreeNodeIDs = familyIDs
						this.expandAncestors(targetNode)
					}
				} else if (this.nodeItems.length === 1) {
					const node = this.nodeItems[0]
					this.selectedNoiDungID = node.NoiDungID
					const familyIDs = this.getAllNodeAndDescendantIDs(node)
					this.selectedNoiDungIDs = familyIDs
					this.activeTreeNodeIDs = familyIDs
					this.expandAncestors(node)
				}
			})
		},
		// Ràng buộc nghiệp vụ: Chỉ cho phép chọn các node danh mục khung (Chương, Bài, Nhóm kỹ năng) của SGK
		isLinkableNode(node) {
			return ['CHUONG', 'BAI', 'NHOM_KY_NANG'].includes(node?.LoaiNoiDung)
		},
		flattenNodes(nodes) {
			return (nodes || []).filter(node => this.isLinkableNode(node))
		},
		buildTree(nodes) {
			const byId = Object.fromEntries((nodes || []).map(node => [node.NoiDungID, { ...node, children: [] }]))
			const roots = []
			Object.values(byId).forEach(node => {
				if (node.ParentID && byId[node.ParentID]) byId[node.ParentID].children.push(node)
				else roots.push(node)
			})
			const sortNodes = list => {
				list.sort((a, b) => (a.ThuTu || 0) - (b.ThuTu || 0))
				list.forEach(node => sortNodes(node.children))
			}
			sortNodes(roots)
			return roots
		},
		getExpandableIDs(nodes) {
			const ids = []
			const walk = list => (list || []).forEach(node => {
				if (node.children && node.children.length) { ids.push(Number(node.NoiDungID)); walk(node.children) }
			})
			walk(nodes)
			return ids
		},
		expandAncestors(node) {
			if (!node) return
			const ancestorIDs = []
			let current = node
			while (current) {
				if (current.ParentID) {
					ancestorIDs.push(Number(current.ParentID))
					current = this.nodeItems.find(n => String(n.NoiDungID) === String(current.ParentID))
				} else {
					break
				}
			}
			const opened = new Set([...(this.openedTreeNodeIDs || []).map(Number), ...ancestorIDs, Number(node.NoiDungID)])
			this.openedTreeNodeIDs = Array.from(opened)
		},
		getAllNodeAndDescendantIDs(node) {
			const ids = []
			const walk = (n) => {
				if (!n) return
				ids.push(String(n.NoiDungID))
				if (n.children && n.children.length) {
					n.children.forEach(child => walk(child))
				}
			}
			walk(node)
			return ids
		},
		isNodeSelected(node) {
			if (!node || (!this.selectedNoiDungID && (!this.selectedNoiDungIDs || !this.selectedNoiDungIDs.length))) return false
			const targetIDs = (this.selectedNoiDungIDs && this.selectedNoiDungIDs.length)
				? this.selectedNoiDungIDs
				: [String(this.selectedNoiDungID)]
			
			// Kiểm tra xem chính node này hoặc bất kỳ node cha/ông/bà nào của nó có nằm trong targetIDs hay không
			let current = node
			while (current) {
				if (targetIDs.includes(String(current.NoiDungID))) return true
				if (!current.ParentID) break
				current = this.nodeItems.find(n => String(n.NoiDungID) === String(current.ParentID))
			}
			return false
		},
		toggleNodeSelection(node) {
			if (!node || !this.isLinkableNode(node)) return
			const isCurrentlySelected = this.isNodeSelected(node)
			
			// Lấy toàn bộ ID của node cha và các node con cháu bên trong
			const familyIDs = this.getAllNodeAndDescendantIDs(node)

			let nextIDs = []
			if (isCurrentlySelected) {
				// Nếu đang chọn mà click lại -> bỏ chọn cả cha lẫn các con
				nextIDs = (this.selectedNoiDungIDs || []).filter(id => !familyIDs.includes(id))
			} else {
				// Nếu chưa chọn -> chọn node cha và toàn bộ các node con bên trong
				const currentIDs = this.selectedNoiDungIDs || (this.selectedNoiDungID ? [String(this.selectedNoiDungID)] : [])
				nextIDs = Array.from(new Set([...currentIDs, ...familyIDs]))
			}

			this.selectedNoiDungIDs = nextIDs
			this.activeTreeNodeIDs = nextIDs
			this.selectedNoiDungID = nextIDs[0] || null
			if (!isCurrentlySelected) {
				this.expandAncestors(node)
			}
		},
		emitValue() {
			const hocLieu = this.hocLieuItems.find(item => String(item.HocLieuID) === String(this.selectedHocLieuID))
			const node = this.nodeItems.find(item => String(item.NoiDungID) === String(this.selectedNoiDungID))
			this.$emit('update:modelValue', {
				HocLieuID: this.selectedHocLieuID || null,
				NoiDungID: this.selectedNoiDungID || null,
				TenHocLieu: hocLieu?.TenHocLieu || this.modelValue?.TenHocLieu || '',
				TenNoiDung: node?.TenNoiDung || this.modelValue?.TenNoiDung || '',
			})
		},
	},
	}
</script>
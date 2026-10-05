<template>
	<div class="uc-mucluc-tree">
		<!-- Dùng v-list hiển thị danh sách phẳng đã làm mượt theo trạng thái mở (flattened visible nodes)
		     giúp cây phân cấp không bị ép hẹp chiều ngang gây vỡ chữ thành cột dọc khi lồng nhiều tầng -->
		<v-list v-if="visibleNodes && visibleNodes.length" nav dense class="py-1 px-1 tree-nav-list">
			<v-list-item
				v-for="row in visibleNodes"
				:key="row.node.NoiDungID"
				:active="isActive(row.node)"
				:class="['mb-1', 'node-tree-item', getNodeClass(row.node), { 'node-root': row.depth === 0, 'node-branch': hasChildNodesOf(row.node), 'node-leaf': !hasChildNodesOf(row.node), 'is-open': isNodeOpen(row.node) }]"
				rounded="md"
				@click="handleRowClick(row.node)"
			>
				<!-- Icon phân loại theo loại nội dung (Chương, Bài, Video, Bài tập,...) -->
				<template v-slot:prepend>
					<div class="d-flex align-center mr-1">
						<!-- Mỗi slot đại diện cho một cấp depth thực tế, giúp node con tự thụt vào kể cả khi phát sinh thêm cấp mới. -->
						<span
							v-for="level in row.depth"
							:key="`indent-${row.node.NoiDungID}-${level}`"
							class="tree-indent-slot"
							aria-hidden="true"
						></span>

						<!-- Icon mũi tên mở/đóng hoặc icon nhánh cho node lá ở cấp con -->
						<!-- Node lá không có chevron nên cần spacer cùng kích thước để icon/text không bị kéo lệch sang trái. -->
						<v-icon
							v-if="hasChildNodesOf(row.node)"
							size="16"
							class="mr-1 node-collapse-icon"
							:color="isActive(row.node) ? 'white' : (row.depth === 0 ? 'indigo-darken-3' : 'slate-600')"
						>
							{{ isNodeOpen(row.node) ? 'mdi-chevron-down' : 'mdi-chevron-right' }}
						</v-icon>
						<span v-else class="tree-collapse-spacer mr-1" aria-hidden="true"></span>
						<v-icon
							size="small"
							:color="getNodeColor(row.node)"
						>
							{{ getIcon(row.node.LoaiNoiDung) }}
						</v-icon>
					</div>
				</template>

				<!-- Tiêu đề mục / bài học: hỗ trợ công thức Toán học KaTeX qua uc-latex-view -->
				<v-list-item-title class="text-wrap" :class="getNodeClass(row.node) + '-title'">
					<uc-latex-view :content="row.node.TenNoiDung || ''" />
					<v-chip v-if="row.node.IsTeacherOnly" size="x-small" color="warning" variant="flat" class="ml-1 font-weight-medium" label>
						<v-icon start size="x-small">mdi-account-tie</v-icon>
						Chỉ GV
					</v-chip>
				</v-list-item-title>

				<!-- Phía bên phải: Badge số phần con và Nút Xem trực tiếp -->
				<template v-slot:append>
					<div class="d-flex align-center flex-shrink-0 ml-1">
						<!-- Badge hiển thị số phần con khi có từ 2 phần con trở lên -->
						<span
							v-if="shouldShowChildCount(row.node)"
							class="node-child-count d-flex align-center text-caption font-weight-bold mr-1"
							:class="row.depth === 0 ? 'text-indigo-darken-3' : 'text-teal-darken-2'"
						>
							<v-icon size="13" class="mr-0.5">mdi-format-list-bulleted</v-icon>
							{{ getChildCount(row.node) }} phần
						</span>

						<!-- Nút Xem trực tiếp đối với bài/hoạt động có nội dung -->
						<v-btn
							v-if="hasDirectPlayableContent(row.node)"
							size="x-small"
							variant="text"
							icon
							:color="isActive(row.node) ? 'white' : 'success'"
							class="node-open-button"
							:aria-label="'Xem ' + (row.node.TenNoiDung || '')"
							:title="'Xem ' + (row.node.TenNoiDung || '')"
							@click.stop="handlePlayableClick(row.node)"
						>
							<v-icon size="16">mdi-play-circle</v-icon>
						</v-btn>
					</div>
				</template>
			</v-list-item>
		</v-list>

		<!-- Empty state khi học liệu chưa có bài học nào trong cây mục lục -->
		<div v-else class="uc-mucluc-tree__empty d-flex flex-column align-center justify-center text-center py-8 px-4">
			<div class="empty-icon-wrap mb-2 d-flex align-center justify-center rounded-circle bg-teal-lighten-5">
				<v-icon size="24" color="teal-darken-2">mdi-text-box-remove-outline</v-icon>
			</div>
			<div class="text-subtitle-2 font-weight-bold text-slate-700 mb-1">
				Chưa có bài học
			</div>
			<div class="empty-state-description text-caption text-grey-darken-1">
				Học liệu này hiện chưa được tạo cây mục lục nội dung.
			</div>
		</div>
	</div>
</template>

<script>
	export default {
		props: {
			items: { type: Array, default: function () { return []; } },
			selectedId: { type: [String, Number], default: null },
			onNodeClick: { type: Function, default: function () {} },
			onHoatDongClick: { type: Function, default: null }
		},
		data() {
			return {
				opened: []
			};
		},
		computed: {
			// Làm phẳng cây mục lục theo trạng thái mở để hiển thị danh sách mượt mà, không bị thu hẹp ngang
			visibleNodes() {
				return this.flattenVisibleNodes(this.items);
			}
		},
		watch: {
			items: {
				handler(newItems) {
					if (newItems && newItems.length > 0) {
						this.expandToSelectedOrFirst(newItems);
					}
				},
				immediate: true,
				deep: true
			},
			selectedId: {
				handler(newSelectedId) {
					if (newSelectedId && this.items && this.items.length > 0) {
						this.expandToSelected(this.items, newSelectedId);
					}
				},
				immediate: true
			}
		},
		methods: {
			// Đếm số lượng phần con trực tiếp của node
			getChildCount(node) {
				return node && Array.isArray(node.children) ? node.children.length : 0;
			},

			// Chỉ hiện số lượng phần con khi có > 1 phần để tránh rác giao diện
			shouldShowChildCount(node) {
				return this.getChildCount(node) > 1;
			},

			// Kiểm tra node có phần tử con hay không
			hasChildNodesOf(node) {
				return this.getChildCount(node) > 0;
			},

			// Kiểm tra xem node có đang được mở rộng các con hay không
			isNodeOpen(node) {
				if (!node || !Array.isArray(this.opened)) return false;
				return this.opened.some(id => String(id) === String(node.NoiDungID));
			},

			// Đệ quy làm phẳng danh sách node hiển thị dựa trên trạng thái mở (opened).
			// Quan hệ cha-con đã được thể hiện bằng thụt lề động và kiểu node; không lặp lại tên node cha
			// dưới node lá để tránh làm mỗi dòng cao hơn và tạo cảm giác danh sách bị ép.
			flattenVisibleNodes(nodes, depth = 0, result = []) {
				if (!Array.isArray(nodes)) return result;
				nodes.forEach(node => {
					if (!node) return;
					result.push({ node, depth });
					if (this.hasChildNodesOf(node) && this.isNodeOpen(node)) {
						this.flattenVisibleNodes(node.children, depth + 1, result);
					}
				});
				return result;
			},

			getNodeClass(node) {
				const loai = String(node && node.LoaiNoiDung || '').toUpperCase();
				return loai === 'CHUONG' ? 'chuong-item' : loai === 'BAI' ? 'bai-item' : 'hoatdong-item';
			},

			getNodeColor(node) {
				if (this.isActive(node)) return 'white';
				const loai = String(node && node.LoaiNoiDung || '').toUpperCase();
				if (loai === 'CHUONG') return 'indigo-darken-2';
				if (loai === 'BAI') return 'blue-darken-3';
				if (loai === 'VIDEO') return 'red-darken-1';
				if (['HTML', 'READING', 'READINGWITHIMAGE'].includes(loai)) return 'teal-darken-2';
				if (['TAILIEU', 'TAI_LIEU'].includes(loai)) return 'blue-grey-darken-1';
				if (loai.startsWith('QUIZ')) return 'deep-orange-darken-1';
				return 'teal-darken-2';
			},

			// Tìm đường dẫn tổ tiên từ gốc tới node được chọn để tự động mở rộng cây
			findAncestorPath(nodes, targetId, currentPath = []) {
				if (!nodes || !Array.isArray(nodes)) return null;
				for (const node of nodes) {
					const newPath = [...currentPath, node.NoiDungID];
					if (String(node.NoiDungID) === String(targetId)) {
						return newPath;
					}
					if (node.children && node.children.length > 0) {
						const found = this.findAncestorPath(node.children, targetId, newPath);
						if (found) return found;
					}
				}
				return null;
			},

			expandToSelectedOrFirst(nodes) {
				if (!nodes || !Array.isArray(nodes) || nodes.length === 0) return;
				if (this.selectedId) {
					this.expandToSelected(nodes, this.selectedId);
				} else {
					this.expandFirstChapterOnly(nodes);
				}
			},

			// Mở rộng tất cả cấp cha của node đang chọn và cuộn riêng trong khung cây (không cuộn window)
			expandToSelected(nodes, selectedId) {
				if (!nodes || !selectedId) return;
				const path = this.findAncestorPath(nodes, selectedId);
				if (path && path.length > 0) {
					const newOpened = new Set(this.opened || []);
					path.forEach(id => newOpened.add(id));
					this.opened = Array.from(newOpened);

					this.$nextTick(() => {
						setTimeout(() => {
							const container = document.querySelector('.uc-main-layout__tree');
							const el = document.querySelector('.node-tree-item.v-list-item--active');
							if (container && el) {
								const top = el.offsetTop - (container.clientHeight / 2) + (el.clientHeight / 2);
								container.scrollTo({ top: Math.max(0, top), behavior: 'smooth' });
							}
						}, 150);
					});
				} else {
					this.expandFirstChapterOnly(nodes);
				}
			},

			expandFirstChapterOnly(nodes) {
				if (!nodes || !Array.isArray(nodes) || nodes.length === 0) return;
				const openedIds = [];
				const firstChapter = nodes[0];
				if (firstChapter && firstChapter.NoiDungID) {
					openedIds.push(firstChapter.NoiDungID);
					if (firstChapter.children && firstChapter.children.length > 0) {
						firstChapter.children.forEach(child => {
							if (child.children && child.children.length > 0 && child.NoiDungID) {
								openedIds.push(child.NoiDungID);
							}
						});
					}
				}
				this.opened = openedIds;
			},

			// Khi click vào hàng: chọn hiển thị nội dung và đóng/mở nhánh con
			handleRowClick(node) {
				if (this.hasChildNodesOf(node)) {
					this.toggleNode(node);
				}
				this.handleClick(node);
			},

			toggleNode(node) {
				if (!node || !this.hasChildNodesOf(node)) return;
				const nodeId = String(node.NoiDungID);
				const isOpen = this.isNodeOpen(node);
				this.opened = isOpen
					? this.opened.filter(id => String(id) !== nodeId)
					: [...this.opened, node.NoiDungID];
			},

			handleClick(node) {
				if (!node) return;
				if (this.onNodeClick) {
					this.onNodeClick(node);
				}
			},

			handlePlayableClick(node) {
				if (node && this.onHoatDongClick) {
					this.onHoatDongClick(node);
				}
			},

			// Kiểm tra xem node có phải bài/hoạt động xem được trực tiếp
			hasDirectPlayableContent(node) {
				if (!node) return false;
				const loai = (node.LoaiNoiDung || '').toUpperCase();
				if (['CHUONG'].includes(loai)) return false;
				const dataJson = node.DataJson == null ? '' : String(node.DataJson).trim();
				const hasValidData = dataJson !== '' && dataJson !== 'null' && dataJson !== '{}';
				return !!hasValidData || ['VIDEO', 'HTML', 'TAILIEU', 'TAI_LIEU', 'SLIDE', 'INTERACTIVE', 'QUIZ_SINGLE_CHOICE', 'QUIZ_MULTIPLE_CHOICE', 'QUIZ_ORDERING', 'QUIZ_MATCHING', 'QUIZ_DRAG_DROP_CATEGORIZE', 'QUIZ_FILL_IN_BLANK', 'QUIZ_CONNECTION', 'QUIZ_COMPOSITE'].includes(loai);
			},

			isActive(node) {
				if (!this.selectedId || !node) return false;
				return String(this.selectedId) === String(node.NoiDungID);
			},

			getIcon(loai) {
				switch ((loai || '').toUpperCase()) {
					case 'CHUONG': return 'mdi-folder-outline';
					case 'BAI': return 'mdi-notebook-outline';
					case 'VIDEO': return 'mdi-play-circle-outline';
					case 'HTML':
					case 'READING':
					case 'READINGWITHIMAGE': return 'mdi-book-open-page-variant-outline';
					case 'TAILIEU':
					case 'TAI_LIEU': return 'mdi-file-document-outline';
					case 'INTERACTIVE': return 'mdi-xml';
					case 'QUIZ_SINGLE_CHOICE': return 'mdi-radiobox-marked';
					case 'QUIZ_MULTIPLE_CHOICE': return 'mdi-checkbox-multiple-marked';
					case 'QUIZ_ORDERING': return 'mdi-order-numeric-ascending';
					case 'QUIZ_MATCHING': return 'mdi-connection';
					case 'QUIZ_DRAG_DROP_CATEGORIZE': return 'mdi-drag';
					case 'QUIZ_FILL_IN_BLANK': return 'mdi-form-textbox';
					case 'QUIZ_CONNECTION': return 'mdi-lan-connect';
					case 'QUIZ_COMPOSITE': return 'mdi-format-list-checks';
					case 'SLIDE': return 'mdi-presentation';
					default: return 'mdi-circle-small';
				}
			}
		}
	}
</script>
<template>
	<div class="uc-tt" tabindex="-1">
    <!-- Thanh loc (che do toan truong) -->
    <div class="uc-tt__bar" v-if="!xemLop">
      <div class="uc-tt__chips">
        <button v-for="c in capOptions" :key="c.value" type="button"
          :class="['uc-tt__chip', cap === c.value ? 'uc-tt__chip--on' : '']" @click="cap = c.value">
          {{ c.text }} <span class="uc-tt__chip-n">{{ demLop(c.value) }}</span>
        </button>
      </div>
      <div class="uc-tt__chips">
        <button type="button" :class="['uc-tt__chip', hien === 'ca' ? 'uc-tt__chip--on' : '']" @click="hien = 'ca'">Môn + GV</button>
        <button type="button" :class="['uc-tt__chip', hien === 'mon' ? 'uc-tt__chip--on' : '']" @click="hien = 'mon'">Môn</button>
        <button type="button" :class="['uc-tt__chip', hien === 'gv' ? 'uc-tt__chip--on' : '']" @click="hien = 'gv'">GV</button>
      </div>
      <input class="uc-tt__search" v-model="tim" placeholder="Tô sáng GV / môn / phòng..." />
      <label class="uc-tt__chk"><input type="checkbox" v-model="chiThieu" /> Chỉ lớp còn thiếu</label>
      <span class="uc-tt__sum">{{ lopHienThi.length }} lớp · {{ tongTiet }} tiết · <b :class="tongThieu ? 'uc-tt__red' : 'uc-tt__green'">thiếu {{ tongThieu }}</b><span v-if="soTrungGV"> · <b class="uc-tt__red">{{ soTrungGV }} ô trùng GV</b></span></span>
    </div>

    <div :class="['uc-tt__layout', xemLop ? 'uc-tt__layout--bs' : '']">
      <!-- ================= BAN SAP LOP ================= -->
      <div v-if="xemLop" class="uc-bs__main">
        <div class="uc-bs__top">
          <button type="button" class="uc-tt__btn" @click="dongBanSap">« Toàn trường</button>
          <button type="button" class="uc-tt__btn" :disabled="!lopTruoc" @click="moLop(lopTruoc)" title="Lớp trước">‹</button>
          <select class="uc-bs__sel" :value="xemLop" @change="moLop($event.target.value)">
            <option v-for="l in tatCaLop" :key="l" :value="l">{{ l }}{{ thieuLop[l] ? '  (thiếu ' + thieuLop[l] + ')' : '' }}</option>
          </select>
          <button type="button" class="uc-tt__btn" :disabled="!lopSau" @click="moLop(lopSau)" title="Lớp sau">›</button>
          <span class="uc-bs__dmsum" v-if="dmLop[xemLop]">Định mức <b :class="dmLop[xemLop].thieu ? 'uc-tt__red' : 'uc-tt__green'">{{ dmLop[xemLop].xep }}/{{ dmLop[xemLop].can }}</b></span>
          <span class="uc-tt__sp"></span>
          <select class="uc-bs__sel uc-bs__sel--them" value="" @change="hienLop($event.target.value); $event.target.value = ''" title="Mở thêm 1 lớp bên cạnh để kéo thả qua lại">
            <option value="">+ Thêm lớp bên cạnh…</option>
            <option v-for="l in tatCaLop" :key="'p' + l" :value="l" :disabled="bsLops.indexOf(l) >= 0">{{ l }}</option>
          </select>
        </div>
        <div class="uc-bs__dm" v-if="dmLop[xemLop]">
          <button v-for="d in dmLop[xemLop].rows" :key="d.MaMon" type="button"
            :class="['uc-bs__dmchip', d.Xep < d.Can ? 'uc-bs__dmchip--thieu' : '']"
            :title="(d.TenMon || d.MaMon) + ' — ' + (d.HoTen || d.MaGV || '') + (d.Xep < d.Can ? ' · bấm để xếp tiết còn thiếu' : ' · bấm để xem lịch GV')"
            @click="bamMonDM(d)">{{ d.MaMon }} <b>{{ d.Xep }}/{{ d.Can }}</b></button>
        </div>
        <div class="uc-bs__hang">
        <div class="uc-bs__lops">
          <div v-for="(L, li) in [xemLop]" :key="'L' + L" class="uc-bs__lopbox">
            <div class="uc-bs__lophead uc-the__head">
              <b>Lớp {{ L }}</b>
              <span v-if="li === 0" class="uc-tt__tag">lớp chính</span>
              <span v-if="dmLop[L]" :class="dmLop[L].thieu ? 'uc-tt__red' : 'uc-tt__green'"> · định mức {{ dmLop[L].xep }}/{{ dmLop[L].can }}</span>
              <span class="uc-tt__sp"></span>
              <button v-if="li > 0" type="button" class="uc-tt__btn" @click="moLop(L)" title="Đổi lớp này thành lớp chính">Làm lớp chính</button>
              <button v-if="li > 0" type="button" class="uc-tt__btn" @click="dongLopPhu(L)" title="Đóng lớp này">×</button>
            </div>
            <table class="uc-bs__grid">
              <thead><tr><th class="uc-bs__corner">Lớp {{ L }}</th><th v-for="t in bsThuL(L)" :key="'h' + t">Thứ {{ t }}</th></tr></thead>
              <tbody>
                <tr v-for="s in bsSlotsL(L)" :key="s.Buoi + s.Tiet" :class="s.Buoi === 'Chieu' && s.Tiet === 1 ? 'uc-bs__chieu1' : ''">
                  <th class="uc-bs__rowhead">{{ s.Buoi === 'Sang' ? 'Sáng' : 'Chiều' }} {{ s.Tiet }}</th>
                  <td v-for="t in bsThuL(L)" :key="t + s.Buoi + s.Tiet"
                    :class="[bsCellClass(L, t, s), hoverCot === t + '|' + s.Buoi + '|' + s.Tiet ? 'uc-ld__cot' : '']" :title="bsCellTitle(L, t, s)" :data-k="t + '|' + s.Buoi + '|' + s.Tiet" :data-lop="L"
                    @click="bsClick(L, t, s, $event)" @dblclick="bsDbl(L, t, s)" @mouseenter="bsHover(L, t, s); hoverCot = t + '|' + s.Buoi + '|' + s.Tiet" @mouseleave="hoverKey = ''"
                    :draggable="!!(bsCell(L, t, s) && bsCell(L, t, s).it && diChuyenDuoc(bsCell(L, t, s).it))"
                    @dragstart="keoTuLuoi(L, t, s, $event)" @dragover.prevent @drop.prevent="thaLenLuoi(L, t, s)">
                    <template v-if="bsCell(L, t, s) && bsCell(L, t, s).it">
                      <template v-if="false">
                        <div class="uc-bs__mon">{{ bsCell(L, t, s).it.MaMon }}</div>
                        <div class="uc-bs__gv">{{ tenNgan(bsCell(L, t, s).it.TenGV) || bsCell(L, t, s).it.MaGV || '' }}</div>
                      </template>
                      <template v-else>
                        <div class="uc-bs__mon">{{ bsCell(L, t, s).it.TenMon || bsCell(L, t, s).it.MaMon }}</div>
                        <div class="uc-bs__gv">{{ bsCell(L, t, s).it.TenGV || bsCell(L, t, s).it.MaGV || '' }}</div>
                        <div v-if="bsCell(L, t, s).it.MaPhong" :class="['uc-bs__phong', phongTrung(bsCell(L, t, s).it) ? 'uc-bs__phong--trung' : '']"
                          :title="phongTrung(bsCell(L, t, s).it) ? 'Phòng ' + bsCell(L, t, s).it.MaPhong + ' đã có lớp khác cùng giờ' : 'Phòng ' + bsCell(L, t, s).it.MaPhong">{{ bsCell(L, t, s).it.MaPhong }}</div>
                      </template>
                      <span v-if="bsCell(L, t, s).it.DaKhoa" class="uc-bs__lock" title="Đã khoá tay"></span>
                      <div v-if="bsNhieu(L, t, s)" class="uc-bs__them2">+ {{ bsNhieu(L, t, s) }}</div>
                    </template>
                  </td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        <!-- The lich lien doi: cung chieu voi lich lop, thang hang theo tiet -->
        <div class="uc-the__day fpScrollbar" v-if="theList.length" @mouseleave="hoverCot = ''">
          <div v-for="th in theList" :key="th.loai + th.ma" :class="['uc-the', 'uc-the--' + th.loai]">
            <div class="uc-the__head">
              <span class="uc-the__ten" :title="th.ten">{{ th.ten }}</span>
              <span class="uc-tt__sp"></span>
              <button v-if="th.loai === 'lop'" type="button" class="uc-ld__x" title="Mở lớp này thành lịch lớn" @click="moLop(th.ma)">⤢</button>
              <button type="button" class="uc-ld__x" title="Ẩn thẻ này" @click="anThe(th)">×</button>
            </div>
            <table class="uc-the__tbl">
              <thead><tr><th v-for="t in bsThuL(xemLop)" :key="'th' + t">T{{ t }}</th></tr></thead>
              <tbody>
                <tr v-for="s in bsSlotsL(xemLop)" :key="s.Buoi + s.Tiet" :class="s.Buoi === 'Chieu' && s.Tiet === 1 ? 'uc-bs__chieu1' : ''">
                  <td v-for="t in bsThuL(xemLop)" :key="t + s.Buoi + s.Tiet"
                    :class="[theCls(th, t, s), hoverCot === t + '|' + s.Buoi + '|' + s.Tiet ? 'uc-ld__cot' : '']" :title="theTitle(th, t, s)"
                    :data-the="th.ma" :data-k="t + '|' + s.Buoi + '|' + s.Tiet"
                    @click="theClick(th, t, s, $event)" @mouseenter="hoverCot = t + '|' + s.Buoi + '|' + s.Tiet; theHover(th, t, s)" @mouseleave="hoverKey = ''"
                    :draggable="theKeoDuoc(th, t, s)" @dragstart="theKeo(th, t, s, $event)" @dragover.prevent @drop.prevent="theTha(th, t, s)">{{ theTxt(th, t, s) }}<div v-if="theRoom(th, t, s)" class="uc-the__ph">{{ theRoom(th, t, s) }}</div></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>
        </div>
        <div :class="['uc-tt__khay', keo ? 'uc-tt__khay--cho' : '']" @dragover.prevent @drop="thaVaoKhay">
          <span class="uc-tt__khaytitle">Khay tạm</span>
          <span v-if="!khayItems.length" class="uc-tt__muted">Kéo 1 tiết thả vào đây (hoặc chọn tiết rồi bấm phím Delete) để nhấc ra, tạo chỗ trống. Kéo thẻ từ khay vào ô để đặt lại — ô đang có tiết thì tiết đó tự bật ra khay.</span>
          <div v-for="k in khayItems" :key="'k' + k.ID" :class="['uc-tt__kcard', sel && sel.kind === 'tiet' && sel.item.ID === k.ID ? 'uc-tt__kcard--sel' : '']"
            draggable="true" @dragstart="keoBatDau(k, $event)" @click="chonTuKhay(k)" :title="'Bấm để chọn (các ô sẽ tô màu) hoặc kéo thả vào ô'">
            <b>{{ k.MaLop }} · {{ k.TenMon || k.MaMon }}</b><span>{{ k.TenGV || k.MaGV }}</span>
            <span class="uc-tt__muted">{{ k.tu && k.tu.Thu ? 'cũ: ' + nhanO(k.tu.Thu, k.tu.Buoi, k.tu.Tiet) : 'mới' }}</span>
            <button v-if="k.tu && k.tu.Thu" type="button" class="uc-tt__kback" title="Trả về chỗ cũ" @click.stop="traVeCho(k)">↩</button>
          </div>
        </div>
      </div>

      <!-- ================= BANG DIEU KHIEN ================= -->
      <div :class="['uc-tt__panel', msg && msg.loai === 'loi' ? 'uc-tt__panel--loi' : '']">
        <div class="uc-tt__prow">
          <span class="uc-tt__ptitle">{{ !sel ? 'Sắp tay' : (sel.kind === 'thieu' ? 'Lấp chỗ trống' : 'Đang chọn') }}</span>
          <span class="uc-tt__sp"></span>
          <template v-if="!nhap">
            <button type="button" class="uc-tt__btn" :disabled="!undo.length || !!dangGui" @click="hoanTac" :title="undo.length ? 'Hoàn tác: ' + undo[undo.length - 1].desc : 'Chưa có thao tác'">↶ Hoàn tác (Ctrl+Z)</button>
            <button type="button" class="uc-tt__btn" :disabled="!redo.length || !!dangGui" @click="lamLai" :title="redo.length ? 'Làm lại: ' + redo[redo.length - 1].desc : 'Không có gì để làm lại'">↷ Làm lại (Ctrl+Y)</button>
          </template>
          <template v-else>
            <button type="button" class="uc-tt__btn" :disabled="!nhap.steps.length" @click="hoanTacNhap">↶ Lùi 1 bước (Ctrl+Z)</button>
            <button type="button" class="uc-tt__btn" :disabled="!redoNhap.length" @click="lamLaiNhap">↷ (Ctrl+Y)</button>
          </template>
        </div>
        <!-- Nhap lien hoan -->
        <div class="uc-tt__nhap" v-if="nhap">
          <div class="uc-tt__prow">
            <span class="uc-tt__nhaptitle">Nháp liên hoàn</span>
            <span>{{ nhap.steps.length }} bước · <b :class="xungDot.length ? 'uc-tt__red' : 'uc-tt__green'">{{ xungDot.length }} xung đột</b><span v-if="khayItems.length"> · <b class="uc-tt__orange">{{ khayItems.length }} tiết trong khay</b></span></span>
          </div>
          <div class="uc-tt__prow">
            <button type="button" class="uc-tt__btn uc-tt__btn--pri" :disabled="!!xungDot.length || !nhap.steps.length || !!dangGui" @click="luuNhap" :title="xungDot.length ? 'Gỡ hết xung đột mới lưu được' : 'Ghi toàn bộ chuỗi vào thời khoá biểu (1 lần)'">{{ xacNhanKhay ? 'Vẫn lưu (gỡ ' + khayItems.length + ' tiết trong khay)' : 'Lưu cả chuỗi' }}</button>
            <button type="button" :class="['uc-tt__btn', xacNhanBo ? 'uc-tt__btn--danger' : '']" @click="boNhap">{{ xacNhanBo ? 'Bấm lần nữa để bỏ nháp' : 'Bỏ nháp' }}</button>
            <span v-if="dangGui" class="uc-tt__muted">đang lưu…</span>
          </div>
          <div v-if="xungDot.length" class="uc-tt__xlist">
            <div class="uc-tt__plabel">Xung đột cần gỡ — bấm tiết muốn dời:</div>
            <div v-for="x in xungDot" :key="x.id" class="uc-tt__xrow">
              <div>{{ x.text }}</div>
              <button v-for="r in rowsGo(x)" :key="r.ID" type="button" class="uc-tt__btn" @click="goXung(r)">Dời {{ r.MaLop }} · {{ r.MaMon }}</button>
            </div>
          </div>
          <div v-if="xacNhanKhay" class="uc-tt__warn">Khay còn {{ khayItems.length }} tiết: nếu lưu bây giờ các tiết này sẽ bị gỡ khỏi lịch (thành tiết còn thiếu). Bấm lại nút lưu để đồng ý, hoặc kéo chúng vào lịch trước.</div>
          <div v-else-if="!xungDot.length && nhap.steps.length && !khayItems.length" class="uc-tt__green">Không còn xung đột — bấm "Lưu cả chuỗi".</div>
          <div class="uc-tt__hist" v-if="nhap.steps.length">
            <div class="uc-tt__plabel">Các bước</div>
            <div v-for="(st, si) in nhap.steps" :key="'n' + si" class="uc-tt__histrow">{{ si + 1 }}. {{ st.desc }}</div>
          </div>
        </div>
        <div class="uc-tt__prow" v-else>
          <button type="button" class="uc-tt__btn uc-tt__btn--nhap" @click="batDauNhap">Bắt đầu nháp liên hoàn</button>
          <span class="uc-tt__muted">đi nhiều bước, cho phép trùng tạm, gỡ dần rồi lưu một lần</span>
        </div>
        <div class="uc-tt__desc" v-if="nhomItems.length">
          <div class="uc-tt__prow"><b>Nhóm {{ nhomItems.length }} tiết</b><span class="uc-tt__muted">(giữ Ctrl / Cmd + bấm để thêm / bớt)</span><span class="uc-tt__sp"></span><button type="button" class="uc-tt__btn" @click="nhomIds = []">Bỏ nhóm (Esc)</button></div>
          <div v-for="it in nhomItems" :key="'n' + it.ID" class="uc-tt__histrow">{{ it.MaLop }} · {{ it.MaMon }} · {{ nhanO(it.Thu, it.Buoi, it.Tiet) }}</div>
          <div class="uc-tt__muted">Kéo 1 tiết trong nhóm thả vào ô đích: cùng lớp = dời cả nhóm (tiết ở chỗ mới đổi về chỗ cũ); thả lên lớp khác hoặc lên ô lớp khác trên dòng giáo viên = đổi khung giờ giữa 2 lớp.</div>
        </div>
        <template v-if="!sel">
          <div class="uc-tt__prow uc-tt__muted">
            {{ xemLop ? 'Bấm 1 tiết trên lịch lớp để xem chỗ có thể chuyển tới. Bấm môn đỏ ở hàng định mức để xếp tiết còn thiếu.' : 'Bấm tên lớp để mở bàn sắp của lớp. Bấm 1 tiết để xem chỗ có thể chuyển tới. Bấm 1 mục còn thiếu để lấp chỗ trống.' }}
          </div>
          <div class="uc-tt__prow" v-if="thieuSorted.length">
            <span class="uc-tt__plabel">Còn thiếu:</span>
            <button type="button" class="uc-tt__btn uc-tt__btn--pri" @click="chayGoiYTatCa" title="Tìm phương án cho mọi tiết còn thiếu">Gợi ý tất cả</button>
            <button v-for="t in thieuSorted" :key="t.MaLop + t.MaMon" type="button" class="uc-tt__tchip"
              :title="(t.TenMon || t.MaMon) + ' — ' + (t.HoTen || t.MaGV || '') + ' · bấm để xếp'"
              @click="chonThieu(t, true)">{{ t.MaLop }} · {{ t.MaMon }}<b v-if="t.Thieu > 1"> ×{{ t.Thieu }}</b></button>
          </div>
        </template>
        <template v-else>
          <div class="uc-tt__prow">
            <span class="uc-tt__pinfo">
              <b>{{ selInfo.lop }}</b> · <b>{{ selInfo.mon }}</b> — {{ selInfo.gv }}<span v-if="selInfo.vitri"> · {{ selInfo.vitri }}</span><span v-if="selInfo.khoa" class="uc-tt__tag">đã khoá</span><span v-if="selInfo.doi" class="uc-tt__tag">tiết đôi</span>
            </span>
          </div>
          <div class="uc-tt__prow">
            <template v-if="sel.kind === 'tiet'">
              <button type="button" class="uc-tt__btn" v-if="!sel.item.khay" @click="duaRaKhay(sel.item)" title="Nhấc tiết ra khay tạm để lấy chỗ trống (phím Delete)">Đưa ra khay</button>
              <button type="button" class="uc-tt__btn" @click="moDoiGV = !moDoiGV">Đổi GV ▾</button>
              <button type="button" class="uc-tt__btn" @click="goTiet">Gỡ tiết</button>
              <button type="button" class="uc-tt__btn" v-if="sel.item.ID > 0 && !nhap" @click="$emit('edit-cell', sel.item)">Sửa…</button>
            </template>
            <button type="button" class="uc-tt__btn uc-tt__btn--pri" v-if="sel.kind === 'thieu'" @click="moGoiY(sel.t)">Gợi ý cách xếp</button>
            <button type="button" class="uc-tt__btn" v-if="!xemLop" @click="moLop(selLop)">Mở bàn sắp lớp</button>
            <button type="button" class="uc-tt__btn" @click="boChon">Bỏ chọn (Esc)</button>
          </div>
          <div class="uc-tt__prow uc-tt__legend" v-if="!xemLop">
            <span><i class="uc-tt__lg uc-tt__n-chuyen"></i>chuyển thẳng</span>
            <span><i class="uc-tt__lg uc-tt__n-doi"></i>đổi chỗ</span>
            <span><i class="uc-tt__lg uc-tt__n-day"></i>đẩy dây chuyền</span>
            <span><i class="uc-tt__lg uc-tt__n-mem"></i>phạm luật mềm</span>
            <span><i class="uc-tt__lg uc-tt__n-cam"></i>không được</span>
          </div>
          <div class="uc-tt__prow uc-tt__legend" v-else>
            <span><i class="uc-tt__lg uc-tt__n-ok"></i>đặt được ngay (bấm 1 lần)</span>
            <span><i class="uc-tt__lg uc-tt__n-gan"></i>được nhưng kéo theo / có lưu ý (bấm 2 lần)</span>
            <span><i class="uc-tt__lg"></i>không màu = vướng — rê chuột xem lý do, vẫn kéo thả được trong nháp</span>
          </div>
          <div class="uc-tt__desc" v-if="planHien">
            <div class="uc-tt__prow"><span :class="'uc-tt__dot uc-tt__n-' + planHien.loai"></span><span>{{ planHien.text }}</span></div>
            <div v-for="(w, wi) in planHien.soft" :key="wi" class="uc-tt__warn">Lưu ý: {{ w }}</div>
            <div v-for="(w, wi) in (planHien.xung || [])" :key="'x' + wi" class="uc-tt__xwarn">Tạo xung đột (gỡ sau): {{ w }}</div>
            <div class="uc-tt__prow" v-if="pending">
              <button type="button" class="uc-tt__btn uc-tt__btn--pri" @click="thucHien(pending.plan)">Thực hiện</button>
              <button type="button" class="uc-tt__btn" @click="pending = null">Huỷ</button>
            </div>
          </div>
          <div class="uc-tt__desc" v-if="xacNhanGo">
            <div>Gỡ tiết {{ selInfo.mon }} của lớp {{ selInfo.lop }} ({{ selInfo.vitri }}) ra khỏi lịch? Tiết sẽ quay về danh sách còn thiếu.</div>
            <div class="uc-tt__prow">
              <button type="button" class="uc-tt__btn uc-tt__btn--danger" @click="thucHienGo">Gỡ</button>
              <button type="button" class="uc-tt__btn" @click="xacNhanGo = false">Huỷ</button>
            </div>
          </div>
          <div class="uc-tt__doigv" v-if="moDoiGV && sel.kind === 'tiet'">
            <div class="uc-tt__muted">Giáo viên cùng dạy {{ selInfo.mon }}<span v-if="capDoi"> — đổi cả cặp tiết đôi</span> · rảnh giờ này trước, ít tiết trước</div>
            <div class="uc-tt__gvlist">
              <button v-for="c in ungVienGV" :key="c.MaGV" type="button" :disabled="c.loai === 'ban-day'"
                :class="['uc-tt__gvopt', 'uc-tt__gvopt--' + c.loai]" :title="c.ghiChu" @click="doiGV(c)">
                <b>{{ c.Ten }}</b><span>{{ c.tai }} tiết · {{ c.ghiChu }}</span>
              </button>
              <span v-if="!ungVienGV.length" class="uc-tt__muted">Không có giáo viên nào khác được phân công môn này</span>
            </div>
          </div>
        </template>
        <div class="uc-tt__goiy" v-if="goiYMuc">
          <div class="uc-tt__prow"><b>Gợi ý cho {{ goiYMuc.MaLop }} · {{ goiYMuc.TenMon || goiYMuc.MaMon }}</b><span class="uc-tt__sp"></span><button type="button" class="uc-tt__btn" @click="goiYMuc = null; goiYDs = []; pending = null">Đóng</button></div>
          <div class="uc-tt__muted">Rê chuột vào phương án để xem trước trên lịch · bấm "Chọn" để đưa vào nháp (chưa lưu)</div>
          <div v-for="(pa, pi) in goiYDs" :key="'gy' + pi" :class="['uc-tt__gyrow', 'uc-tt__gyrow--' + pa.loai]" @mouseenter="xemTruocGoiY(pa)" @mouseleave="xemTruocGoiY(null)">
            <div class="uc-tt__prow">
              <span :class="['uc-tt__gybadge', 'uc-tt__gybadge--' + pa.loai]">{{ pa.loai === 'sach' ? 'Hoán đổi sạch' : (pa.loai === 'luuy' ? 'Có lưu ý' : 'Phá luật') }}</span>
              <span class="uc-tt__muted">{{ pa.soTiet ? 'dời ' + pa.soTiet + ' tiết · ' + (pa.soLop || 0) + ' lớp · ' + (pa.soGV || 0) + ' GV' : 'không dời tiết nào' }}</span>
              <span class="uc-tt__sp"></span>
              <button type="button" class="uc-tt__btn uc-tt__btn--pri" @click="apGoiY(pa)">Chọn</button>
            </div>
            <div>{{ pa.text }}</div>
            <div v-for="(w, wi) in pa.soft" :key="'gw' + wi" class="uc-tt__warn">Lưu ý: {{ w }}</div>
          </div>
        </div>
        <div class="uc-tt__goiy" v-if="goiYTatCa">
          <div class="uc-tt__prow"><b>Gợi ý cho {{ goiYTatCa.length }} tiết còn thiếu</b><span class="uc-tt__sp"></span><button type="button" class="uc-tt__btn" @click="goiYTatCa = null; pending = null">Đóng</button></div>
          <div class="uc-tt__muted">Mỗi dòng là phương án tốt nhất · "Chọn" để đưa vào nháp, bảng tự tính lại · "Xem thêm" để xem các phương án khác</div>
          <div v-for="r in goiYTatCa" :key="'ga' + r.t.MaLop + r.t.MaMon" :class="['uc-tt__gyrow', 'uc-tt__gyrow--' + (r.best ? r.best.loai : 'khong')]" @mouseenter="xemTruocGoiY(r.best)" @mouseleave="xemTruocGoiY(null)">
            <div class="uc-tt__prow">
              <b>{{ r.t.MaLop }} · {{ r.t.MaMon }}<span v-if="r.t.Thieu > 1"> ×{{ r.t.Thieu }}</span></b>
              <span v-if="r.best" :class="['uc-tt__gybadge', 'uc-tt__gybadge--' + r.best.loai]">{{ r.best.loai === 'sach' ? 'Hoán đổi sạch' : (r.best.loai === 'luuy' ? 'Có lưu ý' : 'Phá luật') }}</span>
              <span v-else class="uc-tt__gybadge uc-tt__gybadge--khong">Cần nhiều bước</span>
              <span class="uc-tt__sp"></span>
              <button type="button" class="uc-tt__btn" @click="moGoiY(r.t)">Xem thêm</button>
              <button v-if="r.best" type="button" class="uc-tt__btn uc-tt__btn--pri" @click="apGoiY(r.best, r.t)">Chọn</button>
            </div>
            <div v-if="r.best" class="uc-tt__muted">{{ r.best.text }}<span v-if="r.best.soft.length"> · lưu ý: {{ r.best.soft.join('; ') }}</span></div>
            <div v-else class="uc-tt__muted">Không có chuỗi hoán đổi 1 cặp giờ — dùng khay tạm / kéo thả nhiều bước</div>
          </div>
        </div>
        <div class="uc-tt__desc" v-if="goiYNhap && !nhap">
          <div>Nước này đang bị chặn vì trùng lịch. Có thể <b>đi tạm trong nháp</b> rồi gỡ dần các chỗ trùng:</div>
          <div>{{ goiYNhap.text }}</div>
          <div v-for="(w, wi) in (goiYNhap.xung || [])" :key="'g' + wi" class="uc-tt__xwarn">Sẽ tạo xung đột: {{ w }}</div>
          <div class="uc-tt__prow"><button type="button" class="uc-tt__btn uc-tt__btn--nhap" @click="diTrongNhap">Đi tiếp trong nháp</button><button type="button" class="uc-tt__btn" @click="goiYNhap = null">Thôi</button></div>
        </div>
        <div class="uc-tt__prow" v-if="msg">
          <span :class="msg.loai === 'loi' ? 'uc-tt__red' : 'uc-tt__green'">{{ msg.loai === 'loi' ? 'Không thực hiện được: ' : '' }}{{ msg.text }}</span>
          <span v-if="dangGui" class="uc-tt__muted"> · đang lưu…</span>
        </div>
        <div class="uc-tt__hist" v-if="xemLop && (undo.length || redo.length)">
          <div class="uc-tt__plabel">Lịch sử thao tác</div>
          <div v-for="(e, ei) in undo.slice(-8).reverse()" :key="'u' + ei" class="uc-tt__histrow">{{ e.desc }}</div>
          <div v-for="(e, ei) in redo.slice(-3).reverse()" :key="'r' + ei" class="uc-tt__histrow uc-tt__histrow--redo">(đã hoàn tác) {{ e.desc }}</div>
        </div>
      </div>

      <!-- ================= TOAN TRUONG ================= -->
      <div v-if="!xemLop && nhap && khayItems.length" class="uc-tt__khaywrap"><div :class="['uc-tt__khay', keo ? 'uc-tt__khay--cho' : '']" @dragover.prevent @drop="thaVaoKhay">
          <span class="uc-tt__khaytitle">Khay tạm</span>
          <span v-if="!khayItems.length" class="uc-tt__muted">Kéo 1 tiết thả vào đây (hoặc chọn tiết rồi bấm phím Delete) để nhấc ra, tạo chỗ trống. Kéo thẻ từ khay vào ô để đặt lại — ô đang có tiết thì tiết đó tự bật ra khay.</span>
          <div v-for="k in khayItems" :key="'k' + k.ID" :class="['uc-tt__kcard', sel && sel.kind === 'tiet' && sel.item.ID === k.ID ? 'uc-tt__kcard--sel' : '']"
            draggable="true" @dragstart="keoBatDau(k, $event)" @click="chonTuKhay(k)" :title="'Bấm để chọn (các ô sẽ tô màu) hoặc kéo thả vào ô'">
            <b>{{ k.MaLop }} · {{ k.TenMon || k.MaMon }}</b><span>{{ k.TenGV || k.MaGV }}</span>
            <span class="uc-tt__muted">{{ k.tu && k.tu.Thu ? 'cũ: ' + nhanO(k.tu.Thu, k.tu.Buoi, k.tu.Tiet) : 'mới' }}</span>
            <button v-if="k.tu && k.tu.Thu" type="button" class="uc-tt__kback" title="Trả về chỗ cũ" @click.stop="traVeCho(k)">↩</button>
          </div>
        </div></div>
      <div v-if="!xemLop" class="uc-tt__wrap fpScrollbar" ref="wrap">
      <table class="uc-tt__table">
        <thead>
          <tr>
            <th class="uc-tt__lophead uc-tt__sticky" rowspan="2">Lớp</th>
            <th class="uc-tt__dmhead uc-tt__sticky2" rowspan="2" title="Số tiết đã xếp / định mức (theo phân công giảng dạy)">Định mức</th>
            <th v-for="thu in thuCols" :key="'t' + thu" :colspan="slots.length" class="uc-tt__thu">Thứ {{ thu }}</th>
          </tr>
          <tr>
            <template v-for="thu in thuCols" :key="'s' + thu">
              <th v-for="(s, si) in slots" :key="thu + s.Buoi + s.Tiet"
                :class="['uc-tt__slot', si === 0 ? 'uc-tt__daystart' : '', s.Buoi === 'Chieu' ? 'uc-tt__chieu' : '']">{{ s.Buoi === 'Sang' ? 'S' : 'C' }}{{ s.Tiet }}</th>
            </template>
          </tr>
          <tr v-if="focusGV" class="uc-tt__gvrow">
            <th class="uc-tt__sticky uc-tt__gvhead" colspan="2">
              <span class="uc-tt__gvname" :title="tenGV(focusGV)">{{ tenGV(focusGV) }}</span>
              <span class="uc-tt__muted"> {{ taiGV[focusGV] || 0 }}t</span>
              <button type="button" class="uc-tt__x" title="Đóng" @click="focusGV = ''">×</button>
            </th>
            <template v-for="thu in thuCols" :key="'g' + thu">
              <th v-for="(s, si) in slots" :key="'g' + thu + s.Buoi + s.Tiet"
                :class="gvCellClass(thu, s, si)" :title="gvCellTitle(thu, s)" @click="gvCellClick(thu, s)">{{ gvCellText(thu, s) }}</th>
            </template>
          </tr>
        </thead>
        <tbody>
          <template v-for="g in nhom" :key="'g' + g.khoi">
            <tr class="uc-tt__grow">
              <td class="uc-tt__sticky uc-tt__gname" @click="toggleNhom(g.khoi)">{{ dong[g.khoi] ? '▸' : '▾' }} {{ g.ten }}</td>
              <td :colspan="thuCols.length * slots.length + 1" class="uc-tt__gfill" @click="toggleNhom(g.khoi)">{{ g.lops.length }} lớp<span v-if="g.thieu"> · thiếu {{ g.thieu }} tiết</span></td>
            </tr>
            <template v-if="!dong[g.khoi]">
              <tt-row v-for="lop in g.lops" :key="lop" :lop="lop" :cells="cellsVM[lop] || rong"
                :plans="lop === selLop ? plans : null"
                :sel-id="lop === selLop && sel && sel.kind === 'tiet' ? sel.item.ID : 0"
                :pending-key="pending && pending.lop === lop ? pending.k : ''"
                :phu="phuByLop[lop] || null" :gv-hi="gvHiByLop[lop] || null"
                :thieu-n="thieuLop[lop] || 0" :dm="dmLop[lop] || null" :dm-title="dmTitle(lop)" :hien="hien"
                :sel-row="lop === selLop"
                @lop="moLop(lop)"
                @cell-click="onClick(lop, $event)" @cell-dbl="onDbl($event)" @cell-hover="onHover(lop, $event)"
                @cell-leave="hoverKey = ''" @cell-drag="onDragStart($event)" @gv-name="ghimGV($event)"></tt-row>
            </template>
          </template>
          <tr v-if="nhom.length === 0">
            <td class="uc-tt__empty" :colspan="thuCols.length * slots.length + 2">Chưa có dữ liệu — chọn lần chạy (RunID) ở trên</td>
          </tr>
        </tbody>
      </table>
      </div>
    </div>
  </div>
</template>

<script>
	export default {
		name: 'uc-tkb-toantruong',
  props: {
    items: { type: Array, default: function () { return []; } },
    thieu: { type: Array, default: function () { return []; } },
    // dinhMuc: spAPI_TkbDinhMucLopRun — moi dong (MaLop, MaMon, Can, Xep, CoDinhMuc).
    dinhMuc: { type: Array, default: function () { return []; } },
    // meta: spAPI_TkbSapTayMeta — Loai BAN / MAXNGAY / DOI / GVMON (luat de tu tinh mau nuoc di tren trinh duyet).
    meta: { type: Array, default: function () { return []; } },
    // ketQua: {Success, Message, NewID, seq} — ket qua lan 'apply' gan nhat (trang cha goi spAPI_TkbSapTayThucHien).
    ketQua: { type: Object, default: null },
    fixedThuCols: { type: Array, default: null },
    fixedSlots: { type: Array, default: null }
  },
  emits: ['apply', 'edit-cell', 'lop-click', 'gv-click'],
  // Moi lop la 1 dong con rieng: khi chon/di chuyen chi dong lien quan ve lai (7000 o / 130 lop) — giu thao tac tuc thi.
  components: {
    'tt-row': {
      props: ['lop', 'cells', 'plans', 'selId', 'pendingKey', 'phu', 'gvHi', 'thieuN', 'dm', 'dmTitle', 'hien', 'selRow'],
      emits: ['lop', 'cell-click', 'cell-dbl', 'cell-hover', 'cell-leave', 'cell-drag', 'gv-name'],
      methods: {
        cls: function (c) {
          var a = c.cls;
          if (this.plans) {
            var p = this.plans[c.k];
            if (p) a += ' uc-tt__n-' + p.loai;
            if (this.pendingKey === c.k) a += ' uc-tt__cell--pending';
          }
          if (c.it && this.selId === c.it.ID) a += ' uc-tt__cell--sel';
          if (this.phu && this.phu[c.k]) a += ' uc-tt__cell--phu';
          if (this.gvHi && this.gvHi[c.k]) a += ' uc-tt__cell--gv';
          return a;
        },
        tieuDe: function (c) {
          if (this.plans && this.plans[c.k]) {
            var p = this.plans[c.k];
            return p.text + (p.soft && p.soft.length ? '\nLưu ý: ' + p.soft.join('\nLưu ý: ') : '');
          }
          return c.title;
        }
      },
      template: '<tr :data-lop="lop" :class="selRow ? \'uc-tt__row--sel\' : \'\'">'
        + '<td :class="[\'uc-tt__sticky\', \'uc-tt__lop\', thieuN ? \'uc-tt__lop--thieu\' : \'\']" :title="\'Mở bàn sắp lớp \' + lop" @click="$emit(\'lop\')">{{ lop }}<span v-if="thieuN" class="uc-tt__badge">-{{ thieuN }}</span></td>'
        + '<td :class="[\'uc-tt__sticky2\', \'uc-tt__dm\', dm && dm.thieu ? \'uc-tt__dm--thieu\' : \'uc-tt__dm--du\']" :title="dmTitle" @click="$emit(\'lop\')">'
        + '<template v-if="dm">{{ dm.xep }}/{{ dm.can }}<span v-if="dm.thieuMon" class="uc-tt__dmmon"> {{ dm.thieuMon }}</span></template><template v-else>—</template></td>'
        + '<td v-for="c in cells" :key="c.k" :class="cls(c)" :title="tieuDe(c)" :draggable="!!c.it"'
        + ' @click="$emit(\'cell-click\', c)" @dblclick="$emit(\'cell-dbl\', c)" @mouseenter="$emit(\'cell-hover\', c)" @mouseleave="$emit(\'cell-leave\')"'
        + ' @dragstart="$emit(\'cell-drag\', c)" @dragover.prevent @drop="$emit(\'cell-click\', c)">'
        + '<template v-if="hien === \'ca\' && c.it"><div class="uc-tt__l1">{{ c.it.MaMon }}</div><div class="uc-tt__l2" title="Bấm để xem lịch giáo viên" @click.stop="$emit(\'gv-name\', c.it)">{{ c.l2 }}</div></template>'
        + '<template v-else>{{ c.txt }}</template></td></tr>'
    }
  },
  data: function () {
    return {
      cap: 'all',
      tim: '',
      chiThieu: false,
      hien: 'ca',
      dong: {},
      sel: null,          // {kind:'tiet', item} | {kind:'thieu', t}
      focusGV: '',
      hoverKey: '',
      pending: null,      // {key, plan} cho nuoc vang/cam cho xac nhan
      xacNhanGo: false,
      moDoiGV: false,
      undo: [],           // [{desc, ops, inv, delOldID, idThem}]
      redo: [],
      xemLop: '',         // lop dang mo "ban sap" (rong = xem toan truong)
      nhap: null,         // nhap lien hoan: {pos, gvDoi, them, xoa, steps, nextId} — null = tat
      redoNhap: [],
      xacNhanBo: false,
      goiYNhap: null,     // nuoc bi chan vi trung (ngoai nhap) -> goi y di tiep trong nhap
      keo: null,          // tiet dang keo (keo-tha)
      lopPhu: [],         // cac lop mo them tay canh lop chinh trong ban sap
      anLop: {},          // lop nguoi dung bam x de an (khong tu hien lai trong nhap nay)
      anGV: {},
      anPhong: {},
      hoverCot: '',       // cot gio dang re chuot (sang ca cot tren bang lien doi)
      nhomIds: [],        // nhom tiet chon bang Ctrl/Cmd + bam (keo ca nhom)
      goiYMuc: null,      // tiet thieu dang xem goi y
      goiYDs: [],         // cac phuong an goi y cho goiYMuc
      goiYTatCa: null,    // bang goi y cho moi tiet con thieu
      xacNhanKhay: false, // luu khi khay con tiet -> hoi lai
      rong: [],
      dangGui: null,      // {seq, desc, inv, isUndo}
      seq: 0,
      msg: null,
      capOptions: [
        { text: 'Tất cả', value: 'all' },
        { text: 'Tiểu học', value: 'TH' },
        { text: 'THCS', value: 'THCS' },
        { text: 'THPT', value: 'THPT' },
        { text: 'Nhóm/cụm', value: 'KHAC' }
      ]
    };
  },
  computed: {
    thuCols: function () {
      return (this.fixedThuCols && this.fixedThuCols.length) ? this.fixedThuCols : [2, 3, 4, 5, 6, 7];
    },
    slots: function () {
      if (this.fixedSlots && this.fixedSlots.length) return this.fixedSlots;
      return [
        { Buoi: 'Sang', Tiet: 1 }, { Buoi: 'Sang', Tiet: 2 }, { Buoi: 'Sang', Tiet: 3 }, { Buoi: 'Sang', Tiet: 4 }, { Buoi: 'Sang', Tiet: 5 },
        { Buoi: 'Chieu', Tiet: 1 }, { Buoi: 'Chieu', Tiet: 2 }, { Buoi: 'Chieu', Tiet: 3 }, { Buoi: 'Chieu', Tiet: 4 }
      ];
    },
    // ---------- Chi muc du lieu (tinh 1 lan moi khi nap lai) ----------
    // O cua lop: "Lop|Thu|Buoi|Tiet" -> dong. HOP (hop GV) khong phai tiet cua lop.
    map: function () {
      var m = {};
      this.itemsHL.forEach(function (it) {
        if (it.MaMon === 'HOP') return;
        var k = it.MaLop + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet;
        if (m[k] && !it.nhap) return; // o trung trong nhap: hien tiet vua doi toi
        m[k] = it;
      });
      return m;
    },
    // Lich ban cua GV that (ke ca hop): "MaGV|Thu|Buoi|Tiet" -> [dong]. Dong danh dau cum tach (MaGV = MaMon) bo qua.
    gvIdx: function () {
      var m = {};
      this.itemsHL.forEach(function (it) {
        if (!it.MaGV || it.MaGV === it.MaMon) return;
        var k = it.MaGV + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet;
        (m[k] || (m[k] = [])).push(it);
      });
      return m;
    },
    // 2026-10-09: phong co dinh cua lop theo mon (meta Loai PHONG: cot MaGV = ma lop, Ten = ma phong) — gan cho tiet them moi.
    phongMacDinh: function () {
      var m = {};
      (this.meta || []).forEach(function (r) { if (r.Loai === 'PHONG' && r.MaGV && r.MaMon && r.Ten) m[r.MaGV + '|' + r.MaMon] = r.Ten; });
      return m;
    },
    phongIdx: function () {
      var m = {};
      this.itemsHL.forEach(function (it) {
        if (!it.MaPhong) return;
        var k = it.MaPhong + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet;
        (m[k] || (m[k] = [])).push(it);
      });
      return m;
    },
    // O hop le theo khoi = o ma it nhat 1 lop cung khoi dang co tiet.
    slotKhoi: function () {
      var self = this, m = {};
      this.items.forEach(function (it) {
        if (it.MaMon === 'HOP') return;
        m[self.khoiCua(it.MaLop) + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet] = true;
      });
      return m;
    },
    taiGV: function () {
      var m = {};
      this.itemsHL.forEach(function (it) { if (it.MaGV && it.MaMon !== 'HOP') m[it.MaGV] = (m[it.MaGV] || 0) + 1; });
      return m;
    },
    tenGVMap: function () {
      var m = {};
      this.items.forEach(function (it) { if (it.MaGV && it.TenGV) m[it.MaGV] = it.TenGV; });
      (this.meta || []).forEach(function (r) { if (r.Loai === 'GVMON' && r.MaGV && r.Ten && !m[r.MaGV]) m[r.MaGV] = r.Ten; });
      (this.thieu || []).forEach(function (t) { if (t.MaGV && t.HoTen && !m[t.MaGV]) m[t.MaGV] = t.HoTen; });
      return m;
    },
    ban: function () {
      var m = {};
      (this.meta || []).forEach(function (r) { if (r.Loai === 'BAN') m[r.MaGV + '|' + r.Thu + '|' + r.Buoi + '|' + r.Tiet] = r.Ten || 'GV báo bận'; });
      return m;
    },
    maxNgay: function () {
      var m = {};
      (this.meta || []).forEach(function (r) { if (r.Loai === 'MAXNGAY' && r.SoTiet) m[r.MaMon + '|' + (r.Khoi || '*')] = r.SoTiet; });
      return m;
    },
    doiSet: function () {
      var m = {};
      (this.meta || []).forEach(function (r) { if (r.Loai === 'DOI') m[r.MaMon] = true; });
      return m;
    },
    gvMon: function () {
      var m = {};
      (this.meta || []).forEach(function (r) { if (r.Loai === 'GVMON') (m[r.MaMon] || (m[r.MaMon] = [])).push({ MaGV: r.MaGV, Ten: r.Ten }); });
      return m;
    },
    trungGV: function () {
      var out = {}, idx = this.gvIdx;
      Object.keys(idx).forEach(function (k) {
        var rows = idx[k].filter(function (r) { return r.MaMon !== 'HOP'; });
        if (rows.length > 1) rows.forEach(function (r) { out[r.ID] = true; });
      });
      return out;
    },
    soTrungGV: function () { return Object.keys(this.trungGV).length; },
    dmLop: function () {
      var m = {};
      this.dinhMucHL.forEach(function (d) {
        if (!d.CoDinhMuc) return;
        var o = m[d.MaLop] || (m[d.MaLop] = { can: 0, xep: 0, thieu: 0, mons: [], rows: [] });
        o.can += d.Can || 0;
        o.xep += Math.min(d.Xep || 0, d.Can || 0);
        o.rows.push(d);
        if ((d.Can || 0) > (d.Xep || 0)) { o.thieu += d.Can - d.Xep; o.mons.push(d.MaMon + (d.Can - d.Xep > 1 ? '×' + (d.Can - d.Xep) : '')); }
      });
      Object.keys(m).forEach(function (k) { m[k].thieuMon = m[k].mons.join(' '); });
      return m;
    },
    thieuLop: function () {
      var m = {};
      this.thieuHL.forEach(function (t) { m[t.MaLop] = (m[t.MaLop] || 0) + (t.Thieu || 0); });
      return m;
    },
    thieuSorted: function () {
      var kc = {};
      this.khayItems.forEach(function (r) { if (!r.ao) { var k = r.MaLop + '|' + r.MaMon; kc[k] = (kc[k] || 0) + 1; } });
      return this.thieuHL.map(function (t) {
        var k = t.MaLop + '|' + t.MaMon, n = (t.Thieu || 0) - (kc[k] || 0);
        return n === t.Thieu ? t : Object.assign({}, t, { Thieu: n });
      }).filter(function (t) { return t.Thieu > 0; }).sort(function (a, b) { return a.MaLop.localeCompare(b.MaLop) || a.MaMon.localeCompare(b.MaMon); });
    },
    tatCaLop: function () {
      var s = {};
      this.itemsHL.forEach(function (it) { if (it.MaMon !== 'HOP') s[it.MaLop] = true; });
      this.thieuHL.forEach(function (t) { s[t.MaLop] = true; });
      return Object.keys(s).sort();
    },
    lopHienThi: function () {
      var self = this;
      return this.tatCaLop.filter(function (l) {
        if (self.cap !== 'all' && self.capCua(l) !== self.cap) return false;
        if (self.chiThieu && !self.thieuLop[l] && l !== self.selLop) return false;
        return true;
      });
    },
    nhom: function () {
      var self = this, g = {}, order = [];
      this.lopHienThi.forEach(function (l) {
        var k = self.khoiCua(l);
        if (!g[k]) { g[k] = { khoi: k, ten: k === 'KHAC' ? 'Nhóm / cụm tách' : 'Khối ' + k, lops: [], thieu: 0 }; order.push(k); }
        g[k].lops.push(l);
        g[k].thieu += self.thieuLop[l] || 0;
      });
      order.sort(function (a, b) { return a === 'KHAC' ? 1 : (b === 'KHAC' ? -1 : a.localeCompare(b)); });
      return order.map(function (k) { return g[k]; });
    },
    tongTiet: function () {
      var self = this, n = 0;
      this.lopHienThi.forEach(function (l) {
        self.thuCols.forEach(function (thu) {
          self.slots.forEach(function (s) { if (self.map[l + '|' + thu + '|' + s.Buoi + '|' + s.Tiet]) n++; });
        });
      });
      return n;
    },
    tongThieu: function () {
      var self = this, n = 0;
      this.lopHienThi.forEach(function (l) { n += self.thieuLop[l] || 0; });
      return n;
    },
    timLower: function () { return (this.tim || '').trim().toLowerCase(); },
    // ---------- Nhap lien hoan: du lieu "hieu luc" = du lieu that + cac nuoc di tam trong nhap ----------
    itemsById: function () {
      var m = {};
      this.items.forEach(function (r) { m[r.ID] = r; });
      return m;
    },
    itemsHL: function () {
      var n = this.nhap;
      if (!n) return this.items;
      var out = [];
      this.items.forEach(function (r) {
        if (n.xoa[r.ID]) return;
        var p = n.pos[r.ID], g = n.gvDoi[r.ID];
        if (p && p.khay) return; // dang nam trong khay tam
        if (!p && !g) { out.push(r); return; }
        var c = Object.assign({}, r, p || {});
        if (g) { c.MaGV = g.MaGV; c.TenGV = g.TenGV; }
        c.nhap = true;
        out.push(c);
      });
      n.them.forEach(function (r) { if (!r.khay) out.push(Object.assign({}, r, { nhap: true, ao: true })); });
      return out;
    },
    // Cac tiet dang nam trong khay tam.
    khayItems: function () {
      var n = this.nhap, self = this, out = [];
      if (!n) return out;
      Object.keys(n.pos).forEach(function (id) {
        var p = n.pos[id];
        if (!p.khay || n.xoa[id]) return;
        var r = self.itemsById[id];
        if (!r) return;
        var c = Object.assign({}, r, { khay: true, nhap: true, tu: p.tu, Thu: 0, Buoi: '', Tiet: 0 });
        if (n.gvDoi[id]) { c.MaGV = n.gvDoi[id].MaGV; c.TenGV = n.gvDoi[id].TenGV; }
        out.push(c);
      });
      n.them.forEach(function (r) { if (r.khay) out.push(Object.assign({}, r, { nhap: true, ao: true, Thu: 0, Buoi: '', Tiet: 0 })); });
      return out;
    },
    // Chenh lech so tiet theo (lop|mon) do nhap them/go — de "con thieu" va dinh muc cap nhat ngay.
    deltaNhap: function () {
      var d = {}, n = this.nhap, self = this;
      if (!n) return d;
      n.them.forEach(function (r) { if (r.khay) return; var k = r.MaLop + '|' + r.MaMon; d[k] = (d[k] || 0) + 1; });
      Object.keys(n.pos).forEach(function (id) {
        if (!n.pos[id].khay || n.xoa[id]) return;
        var r = self.itemsById[id];
        if (r) { var k = r.MaLop + '|' + r.MaMon; d[k] = (d[k] || 0) - 1; }
      });
      Object.keys(n.xoa).forEach(function (id) {
        var r = self.itemsById[id];
        if (r) { var k = r.MaLop + '|' + r.MaMon; d[k] = (d[k] || 0) - 1; }
      });
      return d;
    },
    thieuHL: function () {
      var d = this.deltaNhap, out = [], seen = {};
      (this.thieu || []).forEach(function (t) {
        var k = t.MaLop + '|' + t.MaMon; seen[k] = true;
        var n = (t.Thieu || 0) - (d[k] || 0);
        if (n > 0) out.push(Object.assign({}, t, { Thieu: n }));
      });
      var self = this;
      Object.keys(d).forEach(function (k) {
        if (seen[k] || d[k] >= 0) return;
        var p = k.split('|'), dm = (self.dinhMuc || []).filter(function (x) { return x.MaLop === p[0] && x.MaMon === p[1]; })[0] || {};
        out.push({ MaLop: p[0], MaMon: p[1], MaGV: dm.MaGV, TenMon: dm.TenMon, HoTen: dm.HoTen, Thieu: -d[k] });
      });
      return out;
    },
    dinhMucHL: function () {
      var d = this.deltaNhap;
      if (!this.nhap) return this.dinhMuc || [];
      return (this.dinhMuc || []).map(function (r) {
        var k = r.MaLop + '|' + r.MaMon;
        return d[k] ? Object.assign({}, r, { Xep: (r.Xep || 0) + d[k] }) : r;
      });
    },
    // O cua lop co >= 2 tiet (chi xay ra trong nhap): "Lop|Thu|Buoi|Tiet" -> [dong].
    lopNhieu: function () {
      var m = {}, out = {};
      if (!this.nhap) return out;
      this.itemsHL.forEach(function (it) {
        if (it.MaMon === 'HOP') return;
        var k = it.MaLop + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet;
        (m[k] || (m[k] = [])).push(it);
      });
      Object.keys(m).forEach(function (k) { if (m[k].length > 1) out[k] = m[k]; });
      return out;
    },
    // Xung dot can go trong nhap (chi tinh xung dot co dinh toi tiet da doi trong nhap).
    xungDot: function () {
      var self = this, out = [], seen = {};
      if (!this.nhap) return out;
      var chap = this.nhap.chapNhan || {};
      var them = function (loai, key, rows, text) {
        if (!rows.some(function (r) { return r.nhap; })) return;
        if (chap[loai + key]) return; // nguoi sap da chap nhan pha luat nay (vd GV vang hop)
        if (seen[loai + key]) return;
        seen[loai + key] = true;
        out.push({ id: loai + key, loai: loai, text: text, rows: rows });
      };
      Object.keys(this.lopNhieu).forEach(function (k) {
        var rows = self.lopNhieu[k], p = k.split('|');
        them('lop', k, rows, 'Lớp ' + p[0] + ' có ' + rows.length + ' tiết cùng ' + self.nhanO(+p[1], p[2], +p[3]) + ': ' + rows.map(function (r) { return r.MaMon; }).join(', '));
      });
      Object.keys(this.gvIdx).forEach(function (k) {
        var rows = self.gvIdx[k];
        if (rows.length < 2) return;
        var p = k.split('|');
        them('gv', k, rows, self.tenGV(p[0]) + ' trùng ' + self.nhanO(+p[1], p[2], +p[3]) + ': ' + rows.map(function (r) { return r.MaMon === 'HOP' ? 'họp' : r.MaLop + ' ' + r.MaMon; }).join(' + '));
      });
      Object.keys(this.phongIdx).forEach(function (k) {
        var rows = self.phongIdx[k];
        if (rows.length < 2) return;
        var p = k.split('|');
        them('phong', k, rows, 'Phòng ' + p[0] + ' trùng ' + self.nhanO(+p[1], p[2], +p[3]) + ': ' + rows.map(function (r) { return r.MaLop; }).join(' + '));
      });
      return out;
    },
    xungKey: function () {
      var m = {};
      this.xungDot.forEach(function (x) { x.rows.forEach(function (r) { if (r.MaMon !== 'HOP') m[r.MaLop + '|' + r.Thu + '|' + r.Buoi + '|' + r.Tiet] = true; }); });
      return m;
    },
    // Ke hoach "doi gio day cua GV giua 2 lop": khi dang chon 1 tiet, cac tiet CUNG GV o lop khac (tren lich GV).
    gvPlans: function () {
      var out = {}, self = this;
      if (!this.sel || this.sel.kind !== 'tiet' || !this.selGV) return out;
      var src = this.sel.item, g = this.selGV;
      if (src.khay) return out;
      this.itemsHL.forEach(function (r) {
        if (r.MaGV !== g || r.MaLop === src.MaLop || r.MaMon === 'HOP' || !self.diChuyenDuoc(r)) return;
        var k = r.Thu + '|' + r.Buoi + '|' + r.Tiet;
        if (!out[k]) out[k] = self.keHoachDoiGioGV(src, r);
      });
      return out;
    },
    // ---------- Lua chon hien tai ----------
    selLop: function () {
      if (!this.sel) return '';
      return this.sel.kind === 'tiet' ? this.sel.item.MaLop : this.sel.t.MaLop;
    },
    selGV: function () {
      if (!this.sel) return '';
      var g = this.sel.kind === 'tiet' ? this.sel.item.MaGV : this.sel.t.MaGV;
      return this.laGVThat(g, this.sel.kind === 'tiet' ? this.sel.item.MaMon : this.sel.t.MaMon) ? g : '';
    },
    selInfo: function () {
      if (!this.sel) return {};
      if (this.sel.kind === 'tiet') {
        var it = this.sel.item;
        return { lop: it.MaLop, mon: it.TenMon || it.MaMon, gv: it.TenGV || it.MaGV || '', vitri: it.khay ? 'đang ở khay tạm' : this.nhanO(it.Thu, it.Buoi, it.Tiet),
                 khoa: !!it.DaKhoa, doi: !!this.doiSet[it.MaMon] };
      }
      var t = this.sel.t;
      return { lop: t.MaLop, mon: t.TenMon || t.MaMon, gv: t.HoTen || t.MaGV || '', vitri: 'còn thiếu ' + (t.Thieu || 1) + ' tiết', doi: !!this.doiSet[t.MaMon] };
    },
    // Ke hoach nuoc di cho MOI o cua lop dang chon: "Thu|Buoi|Tiet" -> plan.
    plans: function () {
      var self = this, out = {};
      if (!this.sel) return out;
      var lop = this.selLop;
      this.thuCols.forEach(function (thu) {
        self.slots.forEach(function (s) {
          out[thu + '|' + s.Buoi + '|' + s.Tiet] = self.lapKeHoach(lop, { Thu: thu, Buoi: s.Buoi, Tiet: s.Tiet });
        });
      });
      return out;
    },
    // O hien thi cua tung lop (khong phu thuoc lua chon) — dung chung cho dong con.
    cellsVM: function () {
      var self = this, out = {};
      this.lopHienThi.forEach(function (lop) { out[lop] = self.lamCells(lop); });
      return out;
    },
    // ---------- Ban sap lop ----------
    bsMap: function () {
      var m = {};
      if (!this.xemLop) return m;
      this.lamCells(this.xemLop).forEach(function (c) { m[c.k] = c; });
      return m;
    },
    bsKhoi: function () { return this.khoiCua(this.xemLop); },
    // Cac lop dang mo trong ban sap: lop chinh + lop phu.
    // "Domino toi dau hien toi do": lop chinh + lop mo tay + MOI lop da bi cham trong nhap + moi lop dang dinh xung dot.
    bsLops: function () {
      if (!this.xemLop) return [];
      var out = [this.xemLop], an = this.anLop, self = this;
      var them = function (l) { if (l && out.indexOf(l) < 0 && !an[l] && self.khoiCua(l) !== 'KHAC') out.push(l); };
      this.lopPhu.forEach(them);
      this.nhapLops.forEach(them);
      this.xungDot.forEach(function (x) { x.rows.forEach(function (r) { if (r.MaMon !== 'HOP') them(r.MaLop); }); });
      return out;
    },
    // GV lien doi: GV tiet dang chon / dang ghim / bi anh huong boi nuoc dang xem / dinh xung dot.
    ldGVs: function () {
      var out = [], an = this.anGV, self = this;
      var them = function (g, mon) { if (g && self.laGVThat(g, mon) && out.indexOf(g) < 0 && !an[g]) out.push(g); };
      if (this.selGV) them(this.selGV, '');
      if (this.focusGV) them(this.focusGV, '');
      this.nhomItems.forEach(function (r) { them(r.MaGV, r.MaMon); });
      var p = this.planHien;
      if (p && p.dat) p.dat.forEach(function (d) { them(d.MaGV, d.MaMon); });
      this.xungDot.forEach(function (x) { if (x.loai === 'gv') x.rows.forEach(function (r) { them(r.MaGV, r.MaMon); }); });
      return out;
    },
    nhomItems: function () {
      var ids = this.nhomIds;
      if (!ids.length) return [];
      return this.itemsHL.filter(function (r) { return ids.indexOf(r.ID) >= 0; })
        .sort(function (a, b) { return a.Thu - b.Thu || (a.Buoi === b.Buoi ? 0 : (a.Buoi === 'Sang' ? -1 : 1)) || a.Tiet - b.Tiet; });
    },
    // The lich canh lich chinh: GV lien doi truoc, roi lop lien doi, roi phong tranh chap.
    theList: function () {
      var self = this, out = [];
      this.ldGVs.forEach(function (g) { out.push({ loai: 'gv', ma: g, ten: self.tenGV(g) }); });
      this.bsLops.slice(1).forEach(function (L) { out.push({ loai: 'lop', ma: L, ten: 'Lớp ' + L + (self.dmLop[L] ? ' · ' + self.dmLop[L].xep + '/' + self.dmLop[L].can : '') }); });
      this.ldPhongs.forEach(function (ph) { if (!self.anPhong[ph]) out.push({ loai: 'phong', ma: ph, ten: 'Phòng ' + ph }); });
      return out;
    },
    ldPhongs: function () {
      var out = [];
      this.xungDot.forEach(function (x) { if (x.loai === 'phong') { var ph = x.id.slice(5).split('|')[0]; if (out.indexOf(ph) < 0) out.push(ph); } });
      if (this.sel && this.sel.kind === 'tiet' && this.sel.item.MaPhong && out.indexOf(this.sel.item.MaPhong) < 0) out.push(this.sel.item.MaPhong);
      return out;
    },
    // Cot gio: hop cac gio hoc that cua cac khoi dang lien doi.
    ldCols: function () {
      var self = this, khois = {}, out = [];
      this.bsLops.forEach(function (L) { khois[self.khoiCua(L)] = true; });
      var tatCa = !!khois.KHAC || !Object.keys(khois).length;
      this.thuCols.forEach(function (t) {
        var dau = true;
        self.slots.forEach(function (s) {
          var k = t + '|' + s.Buoi + '|' + s.Tiet;
          var ok = tatCa || Object.keys(khois).some(function (kh) { return self.slotKhoi[kh + '|' + k]; });
          if (!ok) return;
          out.push({ Thu: t, Buoi: s.Buoi, Tiet: s.Tiet, k: k, s: s, dau: dau });
          dau = false;
        });
      });
      return out;
    },
    ldNgay: function () {
      var out = [];
      this.ldCols.forEach(function (c) {
        var last = out[out.length - 1];
        if (last && last.thu === c.Thu) last.n++; else out.push({ thu: c.Thu, n: 1 });
      });
      return out;
    },
    // Lop co tiet bi doi / them / go / dua ra khay trong nhap (theo thu tu bi cham).
    nhapLops: function () {
      var n = this.nhap, self = this, out = [];
      if (!n) return out;
      var them = function (l) { if (l && out.indexOf(l) < 0) out.push(l); };
      n.steps.forEach(function (st) {
        st.ghi.forEach(function (g) {
          var r = self.itemsById[g.ID];
          if (r) them(r.MaLop);
          else { var a = n.them.filter(function (x) { return x.ID === g.ID; })[0] || (g.row || null); if (a) them(a.MaLop); }
        });
      });
      return out;
    },
    bsMaps: function () {
      var self = this, out = {};
      this.bsLops.forEach(function (L) {
        var m = {};
        self.lamCells(L).forEach(function (c) { m[c.k] = c; });
        out[L] = m;
      });
      return out;
    },
    bsThu: function () {
      var self = this, k = this.bsKhoi;
      if (k === 'KHAC') return this.thuCols;
      // 2026-10-09: luon hien du Thu 2-6 (ngay khoi nghi — vd khoi 4 di trai nghiem ca T5 tuan 12 — van hien cot,
      // o to gach cheo 'ngoai'); chi an Thu 7 khi khoi khong co tiet nao.
      return this.thuCols.filter(function (t) {
        return t <= 6 || self.slots.some(function (s) { return self.slotKhoi[k + '|' + t + '|' + s.Buoi + '|' + s.Tiet]; });
      });
    },
    bsSlots: function () {
      var self = this, k = this.bsKhoi;
      if (k === 'KHAC') return this.slots;
      return this.slots.filter(function (s) {
        return self.thuCols.some(function (t) { return self.slotKhoi[k + '|' + t + '|' + s.Buoi + '|' + s.Tiet]; });
      });
    },
    lopTruoc: function () { var i = this.tatCaLop.indexOf(this.xemLop); return i > 0 ? this.tatCaLop[i - 1] : ''; },
    lopSau: function () { var i = this.tatCaLop.indexOf(this.xemLop); return i >= 0 && i < this.tatCaLop.length - 1 ? this.tatCaLop[i + 1] : ''; },
    // Lich GV hien duoi lich lop: GV cua tiet dang chon + GV bi anh huong boi nuoc dang xem (doi/day).
    bsGVs: function () {
      var out = [], self = this;
      var a = this.selGV || this.focusGV;
      if (a) out.push(a);
      var p = this.planHien;
      if (p && p.dat) p.dat.forEach(function (d) {
        if (d.item && self.laGVThat(d.item.MaGV, d.item.MaMon) && out.indexOf(d.item.MaGV) < 0 && out.length < 2) out.push(d.item.MaGV);
      });
      return out;
    },
    gvHiByLop: function () {
      var out = {}, g = this.focusGV;
      if (!g) return out;
      this.itemsHL.forEach(function (it) {
        if (it.MaGV !== g || it.MaMon === 'HOP') return;
        (out[it.MaLop] || (out[it.MaLop] = {}))[it.Thu + '|' + it.Buoi + '|' + it.Tiet] = true;
      });
      return out;
    },
    phuByLop: function () {
      var out = {}, p = this.planHien;
      if (!p || !p.dat) return out;
      p.dat.forEach(function (d) {
        if (d.item) (out[d.MaLop] || (out[d.MaLop] = {}))[d.to.Thu + '|' + d.to.Buoi + '|' + d.to.Tiet] = true;
      });
      return out;
    },
    planHien: function () {
      if (this.pending) return this.pending.plan;
      if (!this.sel || !this.hoverKey) return null;
      var p = this.hoverKey.split('|');
      if (p[0] !== this.selLop) return null;
      return this.plans[p[1] + '|' + p[2] + '|' + p[3]] || null;
    },
    capDoi: function () {
      return this.sel && this.sel.kind === 'tiet' ? this.banCap(this.sel.item) : null;
    },
    ungVienGV: function () {
      var self = this;
      if (!this.sel || this.sel.kind !== 'tiet') return [];
      var it = this.sel.item, ds = (this.gvMon[it.MaMon] || []).filter(function (c) { return c.MaGV !== it.MaGV; });
      var cap = this.capDoi;
      var cacO = [it].concat(cap ? [cap] : []);
      return ds.map(function (c) {
        var loai = 'ranh', ghiChu = 'Rảnh giờ này';
        for (var i = 0; i < cacO.length; i++) {
          var o = cacO[i], k = c.MaGV + '|' + o.Thu + '|' + o.Buoi + '|' + o.Tiet;
          var ban = (self.gvIdx[k] || []);
          if (ban.length) { loai = 'ban-day'; ghiChu = ban[0].MaMon === 'HOP' ? 'Đang họp giờ này' : 'Đang dạy ' + ban[0].MaLop; break; }
          if (self.ban[k]) { loai = 'bao-ban'; ghiChu = 'Báo bận: ' + self.ban[k]; }
        }
        return { MaGV: c.MaGV, Ten: c.Ten || c.MaGV, tai: self.taiGV[c.MaGV] || 0, loai: loai, ghiChu: ghiChu };
      }).sort(function (a, b) {
        var r = { 'ranh': 0, 'bao-ban': 1, 'ban-day': 2 };
        return (r[a.loai] - r[b.loai]) || (a.tai - b.tai);
      });
    }
  },
  watch: {
    ketQua: function (kq) {
      var g = this.dangGui, self = this;
      if (!kq || !g || kq.seq !== g.seq) return;
      this.dangGui = null;
      if (!kq.Success) {
        this.msg = { loai: 'loi', text: kq.Message || 'Không lưu được' };
        return;
      }
      // Ma cac tiet vua them (theo thu tu) — de hoan tac / lam lai thay dung ID moi.
      var ids = String(kq.NewIDs || '').split(',').filter(function (x) { return x; }).map(function (x) { return +x; });
      if (!ids.length && kq.NewID) ids = [kq.NewID];
      var e;
      if (g.isUndo) {
        e = this.undo.pop();
        // Hoan tac thao tac co "go tiet" = them lai -> ID moi: thay ID cu o moi buoc con luu.
        // Dua buoc vao danh sach "lam lai" TRUOC roi moi doi ID, de chinh buoc nay cung duoc cap nhat ID moi.
        if (e) this.redo.push(e);
        if (e && e.delOldIDs && ids.length) e.delOldIDs.slice().forEach(function (cu, i) { if (ids[i]) self.doiID(cu, ids[i]); });
        this.msg = { loai: 'ok', text: 'Đã hoàn tác: ' + g.desc };
      } else if (g.isRedo) {
        e = this.redo.pop();
        // Lam lai thao tac co "them tiet" -> ID moi: thay ID cu, buoc hoan tac tuong ung xoa dung ID moi.
        if (e) this.undo.push(e);
        if (e && e.idsThem && e.idsThem.length && ids.length) {
          e.idsThem.slice().forEach(function (cu, i) { if (ids[i]) self.doiID(cu, ids[i]); });
          e.inv = Object.assign({}, e.inv, { del: ids });
          e.idsThem = ids;
        }
        this.msg = { loai: 'ok', text: 'Đã làm lại: ' + g.desc };
      } else {
        var inv = g.inv;
        var soThem = g.soThem || (g.themMoi ? 1 : 0);
        if (soThem && ids.length) inv = Object.assign({}, inv, { del: ids });
        this.undo.push({ desc: g.desc, ops: g.ops, inv: inv, delOldIDs: g.delOldIDs || null, idsThem: soThem ? ids : null });
        if (this.undo.length > 50) this.undo.shift();
        this.redo = [];
        if (g.laNhap) { this.nhap = null; this.redoNhap = []; this.xacNhanBo = false; }
        this.msg = { loai: 'ok', text: 'Đã lưu: ' + g.desc };
      }
      this.boChon();
    },
    items: function () {
      // Sau khi nap lai, lam moi tham chieu tiet dang chon (neu con).
      if (this.sel && this.sel.kind === 'tiet') {
        var id = this.sel.item.ID, f = this.items.find(function (r) { return r.ID === id; });
        if (f) this.sel = { kind: 'tiet', item: f }; else this.sel = null;
      }
    }
  },
  mounted: function () {
    this._onKey = this.onKey.bind(this);
    window.addEventListener('keydown', this._onKey);
  },
  beforeUnmount: function () {
    window.removeEventListener('keydown', this._onKey);
  },
  methods: {
    // ---------- tien ich ----------
    khoiCua: function (lop) {
      var m = /^(\d\d)[A-Za-z]/.exec(lop || '');
      return m ? m[1] : 'KHAC';
    },
    capCua: function (lop) {
      var k = this.khoiCua(lop);
      if (k === 'KHAC') return 'KHAC';
      var n = parseInt(k, 10);
      return n <= 5 ? 'TH' : (n <= 9 ? 'THCS' : 'THPT');
    },
    demLop: function (cap) {
      var self = this;
      return cap === 'all' ? this.tatCaLop.length : this.tatCaLop.filter(function (l) { return self.capCua(l) === cap; }).length;
    },
    toggleNhom: function (k) {
      var d = Object.assign({}, this.dong);
      d[k] = !d[k];
      this.dong = d;
    },
    laGVThat: function (g, mon) { return !!g && g !== mon; },
    tenGV: function (g) { return this.tenGVMap[g] || g; },
    lamCells: function (lop) {
      var self = this, arr = [], hien = this.hien, tim = this.timLower;
      this.thuCols.forEach(function (thu) {
        self.slots.forEach(function (s, si) {
          var it = self.map[lop + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] || null;
          var c = 'uc-tt__cell' + (hien === 'ca' ? ' uc-tt__cell--ca' : '') + (si === 0 ? ' uc-tt__daystart' : '') + (s.Buoi === 'Chieu' ? ' uc-tt__chieu' : '');
          var title = lop + ' · ' + self.nhanO(thu, s.Buoi, s.Tiet);
          var txt = '', l2 = '', mc = '';
          if (!it) { c += ' uc-tt__cell--trong'; title += ' — trống'; }
          else {
            var mon = it.MaMon;
            if (mon === 'SH' || mon === 'HDTN1' || mon === 'CHAOCO') mc = ' uc-tt__m-sh';
            else if (mon === 'TOAN') mc = ' uc-tt__m-toan';
            else if (mon === 'TV' || mon === 'VAN') mc = ' uc-tt__m-van';
            else if (/^(ENG|TA|TAN|TAV)/.test(mon)) mc = ' uc-tt__m-anh';
            else if (mon === 'KHOAPHONG' || it.MaGV === it.MaMon) mc = ' uc-tt__m-khoa';
            c += mc;
            if (it.DaKhoa) c += ' uc-tt__cell--khoa';
            if (self.trungGV[it.ID]) c += ' uc-tt__cell--trung';
            if (it.nhap) c += ' uc-tt__cell--nhap';
            if (self.xungKey[lop + '|' + thu + '|' + s.Buoi + '|' + s.Tiet]) { c += ' uc-tt__cell--xung'; title += '\nXUNG ĐỘT trong nháp'; }
            if (tim) c += self.khop(it) ? ' uc-tt__cell--hit' : ' uc-tt__cell--mo';
            l2 = self.tenNgan(it.TenGV) || it.MaGV || '';
            txt = hien === 'gv' ? l2 : mon;
            title += '\n' + (it.TenMon || mon) + ' — ' + (it.TenGV || it.MaGV || '') + (it.MaPhong ? ' — P.' + it.MaPhong : '')
              + (it.DaKhoa ? '\n(đã khoá tay)' : '') + (self.trungGV[it.ID] ? '\nTRÙNG GV với lớp khác cùng tiết' : '');
          }
          arr.push({ k: thu + '|' + s.Buoi + '|' + s.Tiet, thu: thu, s: s, it: it, cls: c, mc: mc, title: title, txt: txt, l2: l2 });
        });
      });
      return arr;
    },
    // ---------- ban sap lop ----------
    moLop: function (lop) {
      if (!lop) return;
      if (this.sel && this.selLop !== lop) this.boChon();
      var cu = this.xemLop;
      this.lopPhu = this.lopPhu.filter(function (l) { return l !== lop; });
      if (cu && cu !== lop && this.lopPhu.indexOf(cu) < 0) this.lopPhu = [cu].concat(this.lopPhu);
      this.xemLop = lop;
      this.anLop = {}; this.anGV = {};
      this.msg = null;
    },
    dongBanSap: function () {
      var lop = this.xemLop;
      this.xemLop = '';
      this.lopPhu = [];
      this.anLop = {};
      if (lop) this.cuonToiLop(lop);
    },
    bamMonDM: function (d) {
      if (d.Xep < d.Can) {
        var t = this.thieuHL.filter(function (x) { return x.MaLop === d.MaLop && x.MaMon === d.MaMon; })[0]
          || { MaLop: d.MaLop, MaMon: d.MaMon, MaGV: d.MaGV, TenMon: d.TenMon, HoTen: d.HoTen, Thieu: d.Can - d.Xep };
        this.chonThieu(t, false);
      } else if (this.laGVThat(d.MaGV, d.MaMon)) {
        this.boChon();
        this.focusGV = d.MaGV;
      }
    },
    bsCell: function (L, t, s) { var m = this.bsMaps[L]; return m ? (m[t + '|' + s.Buoi + '|' + s.Tiet] || null) : null; },
    bsThuL: function (L) {
      var self = this, k = this.khoiCua(L);
      if (k === 'KHAC') return this.thuCols;
      // 2026-10-09: luon hien du Thu 2-6 (ngay khoi nghi — vd khoi 4 di trai nghiem ca T5 tuan 12 — van hien cot,
      // o to gach cheo 'ngoai'); chi an Thu 7 khi khoi khong co tiet nao.
      return this.thuCols.filter(function (t) {
        return t <= 6 || self.slots.some(function (s) { return self.slotKhoi[k + '|' + t + '|' + s.Buoi + '|' + s.Tiet]; });
      });
    },
    bsSlotsL: function (L) {
      var self = this, k = this.khoiCua(L);
      if (k === 'KHAC') return this.slots;
      return this.slots.filter(function (s) {
        return self.thuCols.some(function (t) { return self.slotKhoi[k + '|' + t + '|' + s.Buoi + '|' + s.Tiet]; });
      });
    },
    bsCellClass: function (L, t, s) {
      var k = t + '|' + s.Buoi + '|' + s.Tiet, c = this.bsCell(L, t, s), a = 'uc-bs__cell', kh = this.khoiCua(L);
      var hopLe = kh === 'KHAC' || this.slotKhoi[kh + '|' + k];
      if (!hopLe) return a + ' uc-bs__cell--ngoai';
      if (c && c.it) a += c.mc + (this.trungGV[c.it.ID] ? ' uc-tt__cell--trung' : '') + (c.it.nhap ? ' uc-tt__cell--nhap' : '')
        + (this.xungKey[L + '|' + k] ? ' uc-tt__cell--xung' : '');
      else a += ' uc-bs__cell--trong';
      if (this.sel && this.selLop === L) {
        var p = this.plans[k];
        if (p) a += this.mauGon(p.loai);
        if (this.pending && this.pending.lop === L && this.pending.k === k) a += ' uc-tt__cell--pending';
      }
      if (c && c.it && this.sel && this.sel.kind === 'tiet' && this.sel.item.ID === c.it.ID) a += ' uc-tt__cell--sel';
      if (c && c.it && this.nhomIds.indexOf(c.it.ID) >= 0) a += ' uc-tt__cell--nhom';
      var phu = this.phuByLop[L];
      if (phu && phu[k]) a += ' uc-tt__cell--phu';
      if (c && c.it && this.focusGV && c.it.MaGV === this.focusGV && !(this.sel && this.sel.kind === 'tiet' && this.sel.item.ID === c.it.ID)) a += ' uc-tt__cell--gv';
      return a;
    },
    phongMD: function (L, mon) { return this.phongMacDinh[L + '|' + mon] || null; },
    // Tiet nay dang chung phong voi lop khac cung gio (nhan phong to do).
    phongTrung: function (it) {
      if (!it || !it.MaPhong) return false;
      return (this.phongIdx[it.MaPhong + '|' + it.Thu + '|' + it.Buoi + '|' + it.Tiet] || []).some(function (r) { return r.ID !== it.ID && r.MaLop !== it.MaLop; });
    },
    bsCellTitle: function (L, t, s) {
      var k = t + '|' + s.Buoi + '|' + s.Tiet;
      if (this.sel && this.selLop === L && this.plans[k]) {
        var p = this.plans[k];
        return p.text + (p.soft && p.soft.length ? '\nLưu ý: ' + p.soft.join('\nLưu ý: ') : '') + (p.xung && p.xung.length ? '\nTạo xung đột: ' + p.xung.join('\nTạo xung đột: ') : '');
      }
      var c = this.bsCell(L, t, s);
      if (!c) { var kh = this.khoiCua(L); if (kh !== 'KHAC' && !this.slotKhoi[kh + '|' + k]) return 'Khối không học giờ này (ngày nghỉ / ngoài giờ học của khối)'; }
      return c ? c.title : '';
    },
    bsClick: function (L, t, s, e) {
      var c = this.bsCell(L, t, s);
      if (!c) return;
      if (e && (e.ctrlKey || e.metaKey)) { this.batNhom(c.it); return; }
      if (this.nhomIds.length) this.nhomIds = [];
      this.onClick(L, c);
    },
    // Ctrl/Cmd + bam: them / bot tiet vao nhom (chi trong 1 lop).
    batNhom: function (it) {
      if (!it || !this.diChuyenDuoc(it)) return;
      var ids = this.nhomIds.slice(), dau = this.nhomItems[0];
      if (dau && dau.MaLop !== it.MaLop) ids = [];
      var i = ids.indexOf(it.ID);
      if (i >= 0) ids.splice(i, 1); else ids.push(it.ID);
      // Tiet dang chon (bam thuong truoc do) cung vao nhom.
      if (this.sel && this.sel.kind === 'tiet' && this.sel.item.MaLop === it.MaLop && ids.indexOf(this.sel.item.ID) < 0 && this.sel.item.ID !== it.ID) ids.unshift(this.sel.item.ID);
      this.boChon();
      this.nhomIds = ids;
    },
    // Dich khung: giu khoang cach cua nhom so voi tiet "neo" (tiet duoc keo), dat neo vao "to".
    khungDich: function (nhom, neo, to) {
      var dThu = to.Thu - neo.Thu, dTiet = to.Tiet - neo.Tiet;
      return nhom.map(function (r) {
        var cungBuoi = r.Thu === neo.Thu && r.Buoi === neo.Buoi;
        return cungBuoi ? { Thu: to.Thu, Buoi: to.Buoi, Tiet: r.Tiet + dTiet } : { Thu: r.Thu + dThu, Buoi: r.Buoi, Tiet: r.Tiet };
      });
    },
    // Tha ca nhom: cung lop -> doi khung trong lop; lop khac -> doi khung gio giua 2 lop.
    thaNhom: function (nhom, neo, lopDich, to) {
      var A = neo.MaLop, self = this;
      var SA = nhom.map(this.oCua), SB = this.khungDich(nhom, neo, to);
      var khB = this.khoiCua(lopDich);
      var sai = SB.filter(function (o) { return khB !== 'KHAC' && !self.slotKhoi[khB + '|' + o.Thu + '|' + o.Buoi + '|' + o.Tiet]; });
      if (sai.length) { this.msg = { loai: 'loi', text: 'Nhóm rơi ra ngoài giờ học: ' + sai.map(function (o) { return self.nhanO(o.Thu, o.Buoi, o.Tiet); }).join(', ') }; return; }
      var trung = SB.some(function (o, i) { return SA[i].Thu === o.Thu && SA[i].Buoi === o.Buoi && SA[i].Tiet === o.Tiet; });
      if (lopDich === A && trung && SB.every(function (o, i) { return SA[i].Thu === o.Thu && SA[i].Buoi === o.Buoi && SA[i].Tiet === o.Tiet; })) return;
      var nhan = function (S) { return S.map(function (o) { return self.nhanO(o.Thu, o.Buoi, o.Tiet); }).join(', '); };
      var dat, text;
      if (lopDich === A) {
        dat = this.hoanDoiKhung(A, SA, SB);
        text = 'Dời nhóm ' + nhom.length + ' tiết lớp ' + A + ' sang ' + nhan(SB);
      } else {
        var dA = this.hoanDoiKhung(A, SA, SB), dB = this.hoanDoiKhung(lopDich, SB, SA);
        dat = dA && dB ? dA.concat(dB) : null;
        text = 'Đổi khung giờ giữa ' + A + ' và ' + lopDich + ': ' + A + ' sang ' + nhan(SB) + ', ' + lopDich + ' sang ' + nhan(SA);
      }
      if (!dat) { this.msg = { loai: 'loi', text: 'Khung đích có giờ học nhóm / khoá phòng — không đổi được' }; return; }
      this.damBaoNhap();
      this.apNhap({ text: text, dat: dat });
      this.nhomIds = [];
    },
    bsDbl: function (L, t, s) { var c = this.bsCell(L, t, s); if (c) this.onDbl(c); },
    bsHover: function (L, t, s) { var c = this.bsCell(L, t, s); if (c) this.onHover(L, c); },
    // Mo them 1 lop canh lop chinh (lop phu moi nhat dung truoc, toi da 2).
    hienLop: function (lop) {
      if (!lop || !this.xemLop || lop === this.xemLop) return;
      if (this.anLop[lop]) { var a = Object.assign({}, this.anLop); delete a[lop]; this.anLop = a; }
      if (this.lopPhu.indexOf(lop) < 0) this.lopPhu = this.lopPhu.concat([lop]);
    },
    dongLopPhu: function (lop) {
      this.lopPhu = this.lopPhu.filter(function (l) { return l !== lop; });
      var a = Object.assign({}, this.anLop); a[lop] = true; this.anLop = a;
      if (this.sel && this.selLop === lop) this.boChon();
    },
    // Sau 1 buoc nhap: lop nao dinh xung dot ma chua mo -> tu mo canh ben de keo tha tiep.
    tuMoLopXung: function () {
      var self = this;
      if (!this.xemLop) return;
      this.xungDot.forEach(function (x) {
        x.rows.forEach(function (r) {
          if (r.MaMon !== 'HOP' && self.bsLops.indexOf(r.MaLop) < 0 && self.khoiCua(r.MaLop) !== 'KHAC') self.hienLop(r.MaLop);
        });
      });
    },
    bsGvRows: function (g, t, s) { return this.gvIdx[g + '|' + t + '|' + s.Buoi + '|' + s.Tiet] || []; },
    bsGvClass: function (g, t, s) {
      var rows = this.bsGvRows(g, t, s), a = 'uc-bs__gvc', self = this;
      var k = t + '|' + s.Buoi + '|' + s.Tiet;
      if (rows.length) {
        if (rows[0].MaMon === 'HOP') a += ' uc-bs__gvc--hop';
        else a += this.bsLops.indexOf(rows[0].MaLop) >= 0 ? ' uc-bs__gvc--lopnay' : ' uc-bs__gvc--day';
        if (rows.length > 1) a += ' uc-bs__gvc--xung';
        if (this.nhomIds.length && rows.some(function (r) { return self.nhomIds.indexOf(r.ID) >= 0; })) a += ' uc-tt__cell--nhom';
        if (g === this.selGV && this.gvPlans[k] && rows[0].MaLop !== this.selLop) a += this.mauGon(this.gvPlans[k].loai);
        if (this.pending && this.pending.key === 'gv|' + k && g === this.selGV) a += ' uc-tt__cell--pending';
        if (this.sel && this.sel.kind === 'tiet' && rows.some(function (r) { return r.ID === self.sel.item.ID; })) a += ' uc-tt__cell--sel';
      } else if (this.ban[g + '|' + k]) a += ' uc-bs__gvc--ban';
      else a += ' uc-bs__gvc--ranh';
      if (this.hoverKey === this.xemLop + '|' + k) a += ' uc-bs__gvc--hover';
      return a;
    },
    bsGvText: function (g, t, s) {
      var rows = this.bsGvRows(g, t, s);
      if (rows.length) return rows[0].MaMon === 'HOP' ? 'Họp' : rows.map(function (r) { return r.MaLop + ' ' + r.MaMon; }).join(', ');
      return this.ban[g + '|' + t + '|' + s.Buoi + '|' + s.Tiet] ? 'bận' : '';
    },
    bsGvTitle: function (g, t, s) {
      var kp = t + '|' + s.Buoi + '|' + s.Tiet;
      if (g === this.selGV && this.gvPlans[kp]) {
        var gp = this.gvPlans[kp];
        return gp.text + (gp.soft && gp.soft.length ? '\nLưu ý: ' + gp.soft.join('\nLưu ý: ') : '') + (gp.xung && gp.xung.length ? '\nTạo xung đột: ' + gp.xung.join('\nTạo xung đột: ') : '');
      }
      var rows = this.bsGvRows(g, t, s), o = this.tenGV(g) + ' · ' + this.nhanO(t, s.Buoi, s.Tiet) + ': ';
      if (rows.length) return o + rows.map(function (r) { return r.MaMon === 'HOP' ? 'họp' : r.MaLop + ' ' + (r.TenMon || r.MaMon); }).join(', ')
        + (rows[0].MaMon !== 'HOP' && this.bsLops.indexOf(rows[0].MaLop) < 0 ? ' — bấm để mở lớp ' + rows[0].MaLop + ' bên cạnh' : '');
      var b = this.ban[g + '|' + t + '|' + s.Buoi + '|' + s.Tiet];
      return o + (b ? 'báo bận (' + b + ')' : 'rảnh');
    },
    bsGvClick: function (g, t, s) {
      var kp = t + '|' + s.Buoi + '|' + s.Tiet;
      // Dang chon 1 tiet cua GV nay + bam tiet cua GV o lop khac -> doi gio day giua 2 lop (luon hoi xac nhan).
      if (this.sel && this.sel.kind === 'tiet' && g === this.selGV && this.gvPlans[kp] && !this.dangGui) {
        var p = this.gvPlans[kp];
        if (p.loai === 'cam') { this.msg = { loai: 'loi', text: p.text }; this.goiYNhap = p.nhapAlt || null; return; }
        if (this.pending && this.pending.key === 'gv|' + kp) { this.thucHien(p); return; }
        this.pending = { key: 'gv|' + kp, lop: '', k: '', plan: p };
        return;
      }
      var rows = this.bsGvRows(g, t, s).filter(function (r) { return r.MaMon !== 'HOP'; });
      if (!rows.length || !this.diChuyenDuoc(rows[0])) return;
      var r = rows[0];
      this.hienLop(r.MaLop);
      this.chonTiet(r, false);
    },

    tenNgan: function (hoTen) {
      if (!hoTen) return '';
      var p = String(hoTen).trim().split(/\s+/);
      return p[p.length - 1];
    },
    nhanO: function (thu, buoi, tiet) { return 'Thứ ' + thu + (buoi === 'Sang' ? ' sáng' : ' chiều') + ' tiết ' + tiet; },
    cellAt: function (lop, thu, s) { return this.map[lop + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] || null; },
    // Tiet khong di chuyen o day: dong danh dau hoc nhom cum tach, khoa phong.
    diChuyenDuoc: function (it) {
      return !!it && it.MaMon !== 'KHOAPHONG' && it.MaMon !== 'HOP' && it.MaGV !== it.MaMon;
    },
    // Tiet con lai cua cap tiet doi (lien ke, cung lop/mon/GV), neu co.
    banCap: function (it) {
      if (!it || !this.doiSet[it.MaMon]) return null;
      var self = this, kq = null;
      [it.Tiet - 1, it.Tiet + 1].forEach(function (t) {
        var o = self.map[it.MaLop + '|' + it.Thu + '|' + it.Buoi + '|' + t];
        if (!kq && o && o.MaMon === it.MaMon && o.MaGV === it.MaGV) kq = o;
      });
      return kq;
    },
    dmTitle: function (lop) {
      var o = this.dmLop[lop];
      if (!o) return 'Chưa có định mức (phân công giảng dạy) cho lớp này';
      return 'Đã xếp ' + o.xep + '/' + o.can + ' tiết định mức\n' + o.rows.map(function (d) {
        return (d.Xep < d.Can ? '✗ ' : '   ') + (d.TenMon || d.MaMon) + ': ' + d.Xep + '/' + d.Can + (d.HoTen ? ' — ' + d.HoTen : '');
      }).join('\n');
    },
    khop: function (it) {
      var t = this.timLower;
      if (!t) return true;
      return [it.MaGV, it.TenGV, it.MaMon, it.TenMon, it.MaPhong].some(function (x) { return x && String(x).toLowerCase().indexOf(t) >= 0; });
    },
    // ---------- hang lich GV ghim ----------
    gvCellClass: function (thu, s, si) {
      var k = this.focusGV + '|' + thu + '|' + s.Buoi + '|' + s.Tiet;
      var c = ['uc-tt__gvc'];
      if (si === 0) c.push('uc-tt__daystart');
      if ((this.gvIdx[k] || []).length) c.push('uc-tt__gvc--day');
      else if (this.ban[k]) c.push('uc-tt__gvc--ban');
      else c.push('uc-tt__gvc--ranh');
      return c;
    },
    gvCellText: function (thu, s) {
      var rows = this.gvIdx[this.focusGV + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] || [];
      if (rows.length) return rows[0].MaMon === 'HOP' ? 'Họp' : rows.map(function (r) { return r.MaLop; }).join('+');
      return this.ban[this.focusGV + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] ? 'bận' : '';
    },
    gvCellTitle: function (thu, s) {
      var k = this.focusGV + '|' + thu + '|' + s.Buoi + '|' + s.Tiet;
      var rows = this.gvIdx[k] || [];
      var o = this.nhanO(thu, s.Buoi, s.Tiet) + ': ';
      if (rows.length) return o + rows.map(function (r) { return r.MaMon === 'HOP' ? 'họp' : r.MaLop + ' ' + r.MaMon; }).join(', ') + ' — bấm để chọn tiết này';
      if (this.ban[k]) return o + 'báo bận (' + this.ban[k] + ')';
      return o + 'rảnh';
    },
    gvCellClick: function (thu, s) {
      var rows = (this.gvIdx[this.focusGV + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] || []).filter(function (r) { return r.MaMon !== 'HOP'; });
      if (rows.length) this.chonTiet(rows[0], true);
    },
    ghimGV: function (it) {
      if (!it || !this.laGVThat(it.MaGV, it.MaMon)) return;
      if (this.anGV[it.MaGV]) { var a = Object.assign({}, this.anGV); delete a[it.MaGV]; this.anGV = a; }
      this.focusGV = this.focusGV === it.MaGV ? '' : it.MaGV;
    },
    // ---------- kiem tra 1 tap dich chuyen (dong thoi) ----------
    // dat: [{item|null, MaLop, MaMon, MaGV, MaPhong, to:{Thu,Buoi,Tiet}}]. Tra ve {hard: chuoi|null, soft: [chuoi]}.
    kiemTra: function (dat, epXung, strict) {
      // choXung: trong nhap lien hoan (hoac khi xem truoc nuoc di cho nhap), trung lop / GV / phong KHONG chan nua
      // ma ghi vao xung[] de nguoi sap go dan. Chi "ngoai gio hoc" va "2 tiet roi cung 1 o trong cung nuoc" la chan cung.
      var self = this, moved = {}, hard = null, soft = [], xung = [], choXung = !strict && (!!this.nhap || !!epXung);
      var loi = function (t) { if (choXung) xung.push(t); else hard = t; };
      dat.forEach(function (p) { if (p.item) moved[p.item.ID] = true; });
      var conLai = function (rows) { return (rows || []).filter(function (r) { return !moved[r.ID]; }); };
      for (var i = 0; i < dat.length && !hard; i++) {
        var p = dat[i], to = p.to, sk = to.Thu + '|' + to.Buoi + '|' + to.Tiet;
        if (to.khay) continue; // dua ra khay tam: khong chiem o nao
        var khoi = this.khoiCua(p.MaLop);
        if (khoi !== 'KHAC' && !this.slotKhoi[khoi + '|' + sk]) { hard = this.nhanO(to.Thu, to.Buoi, to.Tiet) + ' ngoài giờ học của khối ' + khoi; break; }
        var oLop = this.map[p.MaLop + '|' + sk];
        if (oLop && !moved[oLop.ID]) { loi('Lớp ' + p.MaLop + ' đã có ' + oLop.MaMon + ' ở ' + this.nhanO(to.Thu, to.Buoi, to.Tiet)); if (hard) break; }
        for (var j = 0; j < dat.length; j++) {
          if (j === i) continue;
          var q = dat[j];
          if (!q.to.khay && q.to.Thu === to.Thu && q.to.Buoi === to.Buoi && q.to.Tiet === to.Tiet) {
            if (q.MaLop === p.MaLop) hard = 'Hai tiết cùng rơi vào 1 ô của lớp ' + p.MaLop;
            else if (q.MaGV && q.MaGV === p.MaGV && this.laGVThat(p.MaGV, p.MaMon)) hard = 'Giáo viên bị xếp 2 lớp cùng lúc';
          }
        }
        if (hard) break;
        if (this.laGVThat(p.MaGV, p.MaMon)) {
          var gk = p.MaGV + '|' + sk, ban = conLai(this.gvIdx[gk]);
          if (ban.length) { loi(this.tenGV(p.MaGV) + (ban[0].MaMon === 'HOP' ? ' đang họp' : ' đang dạy lớp ' + ban[0].MaLop) + ' ' + this.nhanO(to.Thu, to.Buoi, to.Tiet)); if (hard) break; }
          if (this.ban[gk]) soft.push(this.tenGV(p.MaGV) + ' báo bận ' + this.nhanO(to.Thu, to.Buoi, to.Tiet) + ' (' + this.ban[gk] + ')');
        }
        if (p.MaPhong) {
          var ph = conLai(this.phongIdx[p.MaPhong + '|' + sk]);
          if (ph.length) { loi('Phòng ' + p.MaPhong + ' đang được lớp ' + ph[0].MaLop + ' dùng ' + this.nhanO(to.Thu, to.Buoi, to.Tiet)); if (hard) break; }
        }
        // Luat mem
        var mx = this.maxNgay[p.MaMon + '|' + khoi] || this.maxNgay[p.MaMon + '|*'];
        if (mx) {
          var dem = 1;
          this.slots.forEach(function (s) {
            var o = self.map[p.MaLop + '|' + to.Thu + '|' + s.Buoi + '|' + s.Tiet];
            if (o && !moved[o.ID] && o.MaMon === p.MaMon) dem++;
          });
          dat.forEach(function (q) { if (q !== p && q.MaLop === p.MaLop && q.MaMon === p.MaMon && q.to.Thu === to.Thu) dem++; });
          if (dem > mx) soft.push(p.MaMon + ' quá ' + mx + ' tiết/ngày ở lớp ' + p.MaLop);
        }
        if (this.doiSet[p.MaMon]) {
          var coCap = [to.Tiet - 1, to.Tiet + 1].some(function (t) {
            var o = self.map[p.MaLop + '|' + to.Thu + '|' + to.Buoi + '|' + t];
            if (o && !moved[o.ID] && o.MaMon === p.MaMon) return true;
            return dat.some(function (q) { return q !== p && q.MaLop === p.MaLop && q.MaMon === p.MaMon && q.to.Thu === to.Thu && q.to.Buoi === to.Buoi && q.to.Tiet === t; });
          });
          if (!coCap) soft.push(p.MaMon + ' là môn tiết đôi — ô này không liền tiết cùng môn');
          if (p.item) {
            var cap = this.banCap(p.item);
            if (cap && !moved[cap.ID]) soft.push('Tách cặp tiết đôi ' + p.MaMon + ' (tiết còn lại ở ' + this.nhanO(cap.Thu, cap.Buoi, cap.Tiet) + ')');
          }
        }
        if (to.Thu === 6 && to.Buoi === 'Chieu' && to.Tiet === 4 && khoi >= '06' && khoi !== 'KHAC' && p.MaMon !== 'SH') soft.push('Ô Sinh hoạt lớp cuối tuần');
      }
      var uniq = function (a) { return a.filter(function (x, i) { return a.indexOf(x) === i; }); };
      return { hard: hard, soft: uniq(soft), xung: uniq(xung) };
    },
    datCua: function (it, to) {
      return { item: it, MaLop: it.MaLop, MaMon: it.MaMon, MaGV: it.MaGV, MaPhong: it.MaPhong, to: to };
    },
    // O trong hop le cua 1 lop (de day tiet bi chiem sang).
    oTrongCuaLop: function (lop) {
      var self = this, out = [], khoi = this.khoiCua(lop);
      this.thuCols.forEach(function (thu) {
        self.slots.forEach(function (s) {
          if (!self.map[lop + '|' + thu + '|' + s.Buoi + '|' + s.Tiet] && self.slotKhoi[khoi + '|' + thu + '|' + s.Buoi + '|' + s.Tiet])
            out.push({ Thu: thu, Buoi: s.Buoi, Tiet: s.Tiet });
        });
      });
      return out;
    },
    // ---------- lap ke hoach cho 1 o dich ----------
    lapKeHoach: function (lop, to, epXung) {
      var self = this, sel = this.sel;
      var src = sel.kind === 'tiet' ? sel.item : null;
      var them = sel.kind === 'thieu' ? sel.t : null;
      var ten = src ? src.MaMon : them.MaMon;
      var gv = src ? src.MaGV : them.MaGV;
      var dOn = this.nhanO(to.Thu, to.Buoi, to.Tiet);
      if (src && !src.khay && src.Thu === to.Thu && src.Buoi === to.Buoi && src.Tiet === to.Tiet) return { loai: 'chon', text: 'Tiết đang chọn' };
      var B = this.map[lop + '|' + to.Thu + '|' + to.Buoi + '|' + to.Tiet];
      if (B && !this.diChuyenDuoc(B)) return { loai: 'cam', text: dOn + ': giờ học nhóm / khoá phòng — không đổi được' };
      // Tiet dang o khay: dat vao o nay; o dang co tiet -> tiet do bat ra khay.
      if (src && src.khay) {
        var datK0 = [this.datCua(src, to)].concat(B ? [this.datCua(B, { khay: true })] : []);
        var kt0 = this.kiemTra(datK0, true);
        if (kt0.hard) return { loai: 'cam', text: kt0.hard, soft: [] };
        var l0 = kt0.xung.length ? 'xung' : (kt0.soft.length ? 'mem' : (B ? 'doi' : 'chuyen'));
        return { loai: l0, text: 'Đặt ' + ten + ' từ khay vào ' + dOn + (B ? ', đẩy ' + B.MaMon + ' ra khay' : ''), soft: kt0.soft, xung: kt0.xung, dat: datK0 };
      }
      var datSrc = src ? this.datCua(src, to)
        : { item: null, MaLop: them.MaLop, MaMon: them.MaMon, MaGV: them.MaGV, MaPhong: this.phongMD(them.MaLop, them.MaMon), to: to };
      var thu = [], loiDau = null;
      var thuPhuongAn = function (loai, dat, text) {
        if (!dat) return null;
        var kt = self.kiemTra(dat, epXung);
        if (!loiDau && kt.hard) loiDau = kt.hard;
        if (kt.hard) return null;
        var pa = { loai: loai, dat: dat, text: text, soft: kt.soft, xung: kt.xung };
        thu.push(pa);
        return pa;
      };
      var sach = function (p) { return !p.soft.length && !p.xung.length; };
      // 0) Tiet doi: doi CA CAP sang khung moi (giu nguyen cap), tiet dang o khung dich doi nguoc ve khung cu.
      var cap = src ? this.banCap(src) : null;
      if (cap) {
        var d = to.Tiet - src.Tiet;
        if (!(to.Thu === src.Thu && to.Buoi === src.Buoi && Math.abs(d) < 2)) {
          var blk = this.khoiCap(src), tu = blk.map(this.oCua);
          var den = blk.map(function (b) { return { Thu: to.Thu, Buoi: to.Buoi, Tiet: b.Tiet + d }; });
          var datK = this.hoanDoiKhung(lop, tu, den);
          if (datK) {
            var keo = datK.filter(function (x) { return x.item && x.item.ID !== src.ID && x.item.ID !== cap.ID; }).map(function (x) { return x.MaMon; });
            thuPhuongAn(keo.length ? 'doi' : 'chuyen', datK, 'Dời cả cặp ' + ten + ' sang ' + this.nhanO(den[0].Thu, den[0].Buoi, den[0].Tiet) + '–' + den[1].Tiet
              + (keo.length ? ', đổi chỗ với ' + keo.join(', ') : ''));
          }
        }
      }
      if (!B) {
        thuPhuongAn('chuyen', [datSrc], (src ? 'Chuyển ' + ten + ' sang ' : 'Xếp ' + ten + ' vào ') + dOn);
      } else if (src) {
        thuPhuongAn('doi', [datSrc, this.datCua(B, { Thu: src.Thu, Buoi: src.Buoi, Tiet: src.Tiet })],
          'Đổi chỗ với ' + B.MaMon + ' (' + (B.TenGV || B.MaGV || '') + ')');
      }
      var tot = thu.filter(sach)[0];
      if (!tot) {
        // Day day chuyen 1: o dich dang co B -> day B sang 1 o trong khac cua lop.
        if (B) {
          var trong = this.oTrongCuaLop(lop);
          for (var i = 0; i < trong.length; i++) {
            var u = trong[i];
            var pa = thuPhuongAn('day', [datSrc, this.datCua(B, u)],
              'Đẩy ' + B.MaMon + ' (' + (B.TenGV || B.MaGV || '') + ') sang ' + this.nhanO(u.Thu, u.Buoi, u.Tiet) + ', rồi ' + (src ? 'chuyển ' : 'xếp ') + ten + ' vào ' + dOn);
            if (pa && sach(pa)) break;
          }
        }
        // Day day chuyen 2: o dich trong nhung GV dang day lop khac C -> day C sang o trong cua lop do.
        if (!B && this.laGVThat(gv, ten)) {
          var C = (this.gvIdx[gv + '|' + to.Thu + '|' + to.Buoi + '|' + to.Tiet] || []).filter(function (r) { return !src || r.ID !== src.ID; });
          if (C.length === 1 && this.diChuyenDuoc(C[0])) {
            var c = C[0], trongC = this.oTrongCuaLop(c.MaLop);
            for (var j = 0; j < trongC.length; j++) {
              var v = trongC[j];
              var pa2 = thuPhuongAn('day', [datSrc, this.datCua(c, v)],
                'Chuyển tiết ' + c.MaMon + ' lớp ' + c.MaLop + ' (cùng GV) sang ' + this.nhanO(v.Thu, v.Buoi, v.Tiet) + ', rồi ' + (src ? 'chuyển ' : 'xếp ') + ten + ' vào ' + dOn);
              if (pa2 && sach(pa2)) break;
            }
          }
        }
        tot = thu.filter(sach)[0] || thu.filter(function (p) { return !p.xung.length; })[0] || thu[0];
      }
      if (!tot) {
        var res = { loai: 'cam', text: loiDau || 'Không xếp được vào ' + dOn, soft: [] };
        // Ngoai nhap: nuoc nay chi bi chan vi trung -> goi y "di tiep trong nhap lien hoan".
        if (!this.nhap && !epXung) {
          var alt = this.lapKeHoach(lop, to, true);
          if (alt && alt.loai !== 'cam' && alt.dat) res.nhapAlt = alt;
        }
        return res;
      }
      var loai = tot.loai;
      if (tot.xung.length) loai = 'xung';
      else if (tot.soft.length && (loai === 'chuyen' || loai === 'doi')) loai = 'mem';
      return { loai: loai, text: tot.text, soft: tot.soft, xung: tot.xung, dat: tot.dat };
    },
    // ---------- dich chuyen theo khung (cap tiet doi / doi gio giua 2 lop) ----------
    // Tiet + tiet con lai cua cap (neu co), sap theo tiet.
    khoiCap: function (it) {
      var cap = this.banCap(it);
      return cap ? [it, cap].sort(function (a, b) { return a.Tiet - b.Tiet; }) : [it];
    },
    oCua: function (r) { return { Thu: r.Thu, Buoi: r.Buoi, Tiet: r.Tiet }; },
    // Hoan doi noi dung 2 khung gio cua 1 lop theo vi tri: tiet o tu[i] sang den[i], tiet o den[i] sang tu[i].
    // Tra null neu khung dich co tiet khong di chuyen duoc (hoc nhom / khoa phong).
    hoanDoiKhung: function (lop, tu, den) {
      var self = this, dat = [], daCo = {};
      tu.forEach(function (s) { var r = self.map[lop + '|' + s.Thu + '|' + s.Buoi + '|' + s.Tiet]; if (r) daCo[r.ID] = true; });
      for (var i = 0; i < tu.length; i++) {
        var a = this.map[lop + '|' + tu[i].Thu + '|' + tu[i].Buoi + '|' + tu[i].Tiet];
        var b = this.map[lop + '|' + den[i].Thu + '|' + den[i].Buoi + '|' + den[i].Tiet];
        if (a) dat.push(this.datCua(a, den[i]));
        if (b && !daCo[b.ID]) {
          if (!this.diChuyenDuoc(b)) return null;
          dat.push(this.datCua(b, tu[i]));
        }
      }
      return dat;
    },
    xepLoai: function (kt, coDoi) {
      if (kt.hard) return 'cam';
      if (kt.xung && kt.xung.length) return 'xung';
      if (kt.soft.length) return 'mem';
      return coDoi ? 'doi' : 'chuyen';
    },
    // Doi gio day cua 1 GV giua 2 lop (ca cap tiet doi neu 2 ben deu la cap): lop A va lop B hoan doi 2 khung gio.
    keHoachDoiGioGV: function (src, r) {
      var kA = this.khoiCap(src), kB = this.khoiCap(r);
      if (kA.length !== kB.length) { kA = [src]; kB = [r]; }
      var SA = kA.map(this.oCua), SB = kB.map(this.oCua);
      var dA = this.hoanDoiKhung(src.MaLop, SA, SB), dB = this.hoanDoiKhung(r.MaLop, SB, SA);
      var gv = this.tenGV(src.MaGV);
      var nhan = function (S, self) { return self.nhanO(S[0].Thu, S[0].Buoi, S[0].Tiet) + (S.length > 1 ? '–' + S[S.length - 1].Tiet : ''); };
      var text = 'Đổi giờ dạy của ' + gv + ': lớp ' + src.MaLop + ' sang ' + nhan(SB, this) + ', lớp ' + r.MaLop + ' sang ' + nhan(SA, this);
      if (!dA || !dB) return { loai: 'cam', text: text + ' — khung đích có giờ học nhóm / khoá phòng', soft: [] };
      var dat = dA.concat(dB);
      var keo = dat.filter(function (d) { return d.item && d.item.MaGV !== src.MaGV; }).map(function (d) { return d.MaLop + ' ' + d.MaMon; });
      if (keo.length) text += ' (kéo theo: ' + keo.join(', ') + ')';
      var kt = this.kiemTra(dat, false);
      var p = { loai: this.xepLoai(kt, true), text: kt.hard ? text + ' — ' + kt.hard : text, soft: kt.soft, xung: kt.xung, dat: kt.hard ? null : dat, gioGV: true };
      if (kt.hard && !this.nhap) {
        var kt2 = this.kiemTra(dat, true);
        if (!kt2.hard) p.nhapAlt = { loai: 'xung', text: text, soft: kt2.soft, xung: kt2.xung, dat: dat };
      }
      return p;
    },
    rowsGo: function (x) {
      var self = this;
      return x.rows.filter(function (r) { return r.MaMon !== 'HOP' && self.diChuyenDuoc(r); });
    },
    diTrongNhap: function () {
      var p = this.goiYNhap;
      if (!p) return;
      this.batDauNhap();
      this.apNhap(p);
    },
    bsNhieu: function (L, t, s) {
      var rows = this.lopNhieu[L + '|' + t + '|' + s.Buoi + '|' + s.Tiet];
      if (!rows) return '';
      var c = this.bsCell(L, t, s), id = c && c.it ? c.it.ID : 0;
      return rows.filter(function (r) { return r.ID !== id; }).map(function (r) { return r.MaMon; }).join(', ');
    },
    // ---------- Khay tam: nhac tiet ra ngoai luoi de co cho trong, roi keo vao lai ----------
    // Bat nhap im lang (khi nguoi dung keo tha / dua ra khay ma chua bat nhap).
    damBaoNhap: function () {
      if (this.nhap) return;
      this.nhap = { pos: {}, gvDoi: {}, them: [], xoa: {}, steps: [], nextId: -1, chapNhan: {} };
      this.redoNhap = [];
      this.xacNhanBo = false;
    },
    nhanKhay: function (it) {
      var tu = it.tu || {};
      return it.MaLop + ' · ' + (it.TenMon || it.MaMon) + ' · ' + (it.TenGV || it.MaGV || '') + (tu.Thu ? ' (cũ: ' + this.nhanO(tu.Thu, tu.Buoi, tu.Tiet) + ')' : ' (tiết còn thiếu)');
    },
    duaRaKhay: function (it) {
      if (!it || !this.diChuyenDuoc(it) || it.khay) return;
      this.damBaoNhap();
      this.apNhap({ text: 'Nhấc ' + it.MaMon + ' lớp ' + it.MaLop + ' (' + this.nhanO(it.Thu, it.Buoi, it.Tiet) + ') ra khay',
                    dat: [this.datCua(it, { khay: true })] });
    },
    // Tha 1 tiet (tu khay / tu luoi / tu danh sach con thieu) vao o "to" cua lop "lop".
    // O dang co tiet khac -> tiet do tu bat ra khay. Chap nhan trung (gỡ sau trong nhap).
    thaVao: function (x, lop, to) {
      if (!x || this.dangGui) return;
      if (x.MaLop !== lop) { this.msg = { loai: 'loi', text: 'Tiết của lớp ' + x.MaLop + ' chỉ đặt vào lịch lớp ' + x.MaLop }; return; }
      var khoi = this.khoiCua(lop), sk = to.Thu + '|' + to.Buoi + '|' + to.Tiet;
      if (khoi !== 'KHAC' && !this.slotKhoi[khoi + '|' + sk]) { this.msg = { loai: 'loi', text: this.nhanO(to.Thu, to.Buoi, to.Tiet) + ' ngoài giờ học của khối ' + khoi }; return; }
      if (x.ID && !x.khay && x.Thu === to.Thu && x.Buoi === to.Buoi && x.Tiet === to.Tiet) return;
      var B = this.map[lop + '|' + sk];
      if (B && x.ID && B.ID === x.ID) return;
      if (B && !this.diChuyenDuoc(B)) { this.msg = { loai: 'loi', text: this.nhanO(to.Thu, to.Buoi, to.Tiet) + ' là giờ học nhóm / khoá phòng' }; return; }
      this.damBaoNhap();
      var dat = [];
      if (x.ID) dat.push(this.datCua(x, to));
      else dat.push({ item: null, MaLop: x.MaLop, MaMon: x.MaMon, MaGV: x.MaGV, MaPhong: this.phongMD(x.MaLop, x.MaMon), TenMon: x.TenMon, TenGV: x.HoTen, to: to });
      if (B) dat.push(this.datCua(B, { khay: true }));
      this.apNhap({ text: 'Đặt ' + x.MaMon + ' lớp ' + lop + ' vào ' + this.nhanO(to.Thu, to.Buoi, to.Tiet) + (B ? ', đẩy ' + B.MaMon + ' ra khay' : ''), dat: dat });
    },
    traVeCho: function (it) {
      var tu = it.tu;
      if (!tu || !tu.Thu) return;
      this.thaVao(it, it.MaLop, { Thu: tu.Thu, Buoi: tu.Buoi, Tiet: tu.Tiet });
    },
    keoBatDau: function (x, e) {
      this.keo = x;
      if (e && e.dataTransfer) { e.dataTransfer.effectAllowed = 'move'; try { e.dataTransfer.setData('text/plain', 'tkb'); } catch (er) { /* bo qua */ } }
    },
    keoTuLuoi: function (L, t, s, e) {
      var c = this.bsCell(L, t, s);
      if (c && c.it && this.nhomIds.indexOf(c.it.ID) >= 0 && this.nhomItems.length > 1) {
        this.keo = { nhom: this.nhomItems.slice(), neo: c.it };
        if (e && e.dataTransfer) { e.dataTransfer.effectAllowed = 'move'; try { e.dataTransfer.setData('text/plain', 'tkb'); } catch (er) { /* bo qua */ } }
        return;
      }
      if (c && c.it && this.diChuyenDuoc(c.it)) this.keoBatDau(c.it, e);
    },
    thaLenLuoi: function (L, t, s) {
      var x = this.keo;
      this.keo = null;
      if (x && x.nhom) { this.thaNhom(x.nhom, x.neo, L, { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet }); return; }
      if (x) this.thaVao(x, L, { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet });
    },
    keoTuLichGV: function (g, t, s, e) {
      var rows = this.bsGvRows(g, t, s).filter(function (r) { return r.MaMon !== 'HOP'; });
      if (rows.length && this.diChuyenDuoc(rows[0])) this.keoBatDau(rows[0], e);
    },
    // Tha len lich GV: dat tiet vao gio do cua chinh lop cua tiet (GV cua tiet giu nguyen).
    thaLenLichGV: function (g, t, s) {
      var x = this.keo;
      this.keo = null;
      if (x && x.nhom) {
        // Tha len o cua GV dang day lop khac -> doi khung gio voi lop do; o trong -> doi trong lop cua nhom.
        var rows = this.bsGvRows(g, t, s).filter(function (r) { return r.MaMon !== 'HOP'; });
        var dich = rows.length && rows[0].MaLop !== x.neo.MaLop ? rows[0].MaLop : x.neo.MaLop;
        this.thaNhom(x.nhom, x.neo, dich, { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet });
        return;
      }
      if (x) this.thaVao(x, x.MaLop, { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet });
    },
    // Mau gon cho ban sap: chi 3 muc de de doc.
    mauGon: function (loai) {
      if (loai === 'chon') return ' uc-tt__n-chon';
      if (loai === 'chuyen' || loai === 'doi') return ' uc-tt__n-ok';
      if (loai === 'day' || loai === 'mem') return ' uc-tt__n-gan';
      return '';
    },
    anThe: function (th) {
      if (th.loai === 'lop') this.dongLopPhu(th.ma);
      else if (th.loai === 'gv') this.anDongGV(th.ma);
      else { var a = Object.assign({}, this.anPhong); a[th.ma] = true; this.anPhong = a; }
    },
    theCls: function (th, t, s) {
      if (th.loai === 'lop') return 'uc-the__c ' + this.bsCellClass(th.ma, t, s);
      if (th.loai === 'gv') return 'uc-the__c ' + this.bsGvClass(th.ma, t, s);
      return 'uc-the__c ' + this.ldPhongClass(th.ma, { k: t + '|' + s.Buoi + '|' + s.Tiet });
    },
    theTxt: function (th, t, s) {
      var c = { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet, s: s, k: t + '|' + s.Buoi + '|' + s.Tiet };
      var gon = function (l) { return String(l || '').replace(/^0(\d)/, '$1'); };
      if (th.loai === 'lop') return this.ldTxtLop(th.ma, c);
      if (th.loai === 'gv') {
        var rows = this.bsGvRows(th.ma, t, s);
        if (rows.length) return rows[0].MaMon === 'HOP' ? 'họp' : rows.map(function (r) { return gon(r.MaLop); }).join('+');
        return this.ban[th.ma + '|' + c.k] ? 'bận' : '';
      }
      return this.ldPhongRows(th.ma, c).map(function (r) { return gon(r.MaLop); }).join('+');
    },
    theTitle: function (th, t, s) {
      if (th.loai === 'lop') return this.bsCellTitle(th.ma, t, s);
      if (th.loai === 'gv') return this.bsGvTitle(th.ma, t, s);
      return this.ldPhongTitle(th.ma, { Thu: t, Buoi: s.Buoi, Tiet: s.Tiet, k: t + '|' + s.Buoi + '|' + s.Tiet });
    },
    theClick: function (th, t, s, e) {
      if (th.loai === 'lop') this.bsClick(th.ma, t, s, e);
      else if (th.loai === 'gv') this.bsGvClick(th.ma, t, s);
    },
    theHover: function (th, t, s) { if (th.loai === 'lop') this.bsHover(th.ma, t, s); },
    theKeoDuoc: function (th, t, s) {
      if (th.loai === 'lop') { var c = this.bsCell(th.ma, t, s); return !!(c && c.it && this.diChuyenDuoc(c.it)); }
      if (th.loai === 'gv') return this.bsGvKeoDuoc(th.ma, t, s);
      return false;
    },
    theKeo: function (th, t, s, e) {
      if (th.loai === 'lop') this.keoTuLuoi(th.ma, t, s, e);
      else if (th.loai === 'gv') this.keoTuLichGV(th.ma, t, s, e);
    },
    theTha: function (th, t, s) {
      if (th.loai === 'lop') this.thaLenLuoi(th.ma, t, s);
      else if (th.loai === 'gv') this.thaLenLichGV(th.ma, t, s);
      else this.keo = null;
    },
    // 2026-10-09: dong phu trong the canh lich (giong sTKB): the GV/lop -> phong cua tiet; the phong -> mon dang hoc.
    theRoom: function (th, t, s) {
      if (th.loai === 'gv') {
        var ph = [];
        this.bsGvRows(th.ma, t, s).forEach(function (r) { if (r.MaPhong && ph.indexOf(r.MaPhong) < 0) ph.push(r.MaPhong); });
        return ph.join('+');
      }
      if (th.loai === 'lop') { var x = this.bsCell(th.ma, t, s); return x && x.it && x.it.MaPhong ? x.it.MaPhong : ''; }
      var mons = [];
      this.ldPhongRows(th.ma, { k: t + '|' + s.Buoi + '|' + s.Tiet }).forEach(function (r) { if (mons.indexOf(r.MaMon) < 0) mons.push(r.MaMon); });
      return mons.join('+');
    },
    ldTxtLop: function (L, c) {
      var x = this.bsCell(L, c.Thu, c.s);
      return x && x.it ? x.it.MaMon : '';
    },
    ldTxtGV: function (g, c) {
      var rows = this.bsGvRows(g, c.Thu, c.s);
      if (rows.length) return rows[0].MaMon === 'HOP' ? 'Họp' : rows.map(function (r) { return r.MaLop; }).join('+');
      return this.ban[g + '|' + c.k] ? 'bận' : '';
    },
    ldPhongRows: function (ph, c) { return this.phongIdx[ph + '|' + c.k] || []; },
    ldTxtPhong: function (ph, c) { return this.ldPhongRows(ph, c).map(function (r) { return r.MaLop; }).join('+'); },
    ldPhongClass: function (ph, c) {
      var n = this.ldPhongRows(ph, c).length;
      return n > 1 ? 'uc-bs__gvc uc-bs__gvc--xung uc-bs__gvc--day' : (n ? 'uc-bs__gvc uc-bs__gvc--day' : 'uc-bs__gvc uc-bs__gvc--ranh');
    },
    ldPhongTitle: function (ph, c) {
      var rows = this.ldPhongRows(ph, c);
      return 'Phòng ' + ph + ' · ' + this.nhanO(c.Thu, c.Buoi, c.Tiet) + ': ' + (rows.length ? rows.map(function (r) { return r.MaLop + ' ' + r.MaMon; }).join(', ') : 'trống');
    },
    anDongGV: function (g) {
      var a = Object.assign({}, this.anGV); a[g] = true; this.anGV = a;
      if (this.focusGV === g) this.focusGV = '';
    },
    bsGvKeoDuoc: function (g, t, s) {
      return this.bsGvRows(g, t, s).some(function (r) { return r.MaMon !== 'HOP'; });
    },
    thaVaoKhay: function () {
      var x = this.keo;
      this.keo = null;
      if (x && x.nhom) { var self = this; this.damBaoNhap(); this.apNhap({ text: 'Nhấc nhóm ' + x.nhom.length + ' tiết lớp ' + x.neo.MaLop + ' ra khay', dat: x.nhom.map(function (r) { return self.datCua(r, { khay: true }); }) }); this.nhomIds = []; return; }
      if (x && x.ID && !x.khay) this.duaRaKhay(x);
    },
    chonTuKhay: function (it) {
      this.hienLop(it.MaLop);
      this.chonTiet(it, false);
    },
    // ---------- Goi y sap tiet con thieu: chuoi Kempe + pha luat toi thieu ----------
    // Chuoi Kempe theo khung: A[i] <-> B[i] (1 hoac 2 gio lien nhau). Tiet thieu m dat vao A[iT].
    // Tiet o A[i] dung voi m (cung lop / GV) chuyen sang B[i]; tiet o B[i] dung voi no chuyen nguoc ve A[i] ...
    // Tiet doi: neu tiet con lai cua cap nam o khung kia cua cung danh sach -> keo theo de cap khong bi tach.
    chuoiKempe: function (m, A, B, iT) {
      var self = this, L = m.MaLop, G = m.MaGV, sangB = {}, sangA = {}, q = [], hong = false, dem = 0;
      var kA = A.map(function (o) { return o.Thu + '|' + o.Buoi + '|' + o.Tiet; });
      var kB = B.map(function (o) { return o.Thu + '|' + o.Buoi + '|' + o.Tiet; });
      var viTri = function (e, ks) { return ks.indexOf(e.Thu + '|' + e.Buoi + '|' + e.Tiet); };
      var them = function (e, huong, i) {
        if (hong || !e) return;
        // Tiet co dinh (hop, sinh hoat, HDTN, chao co, hoc nhom) khong tu dong doi trong chuoi goi y.
        if (e.MaMon === 'HOP' || !self.diChuyenDuoc(e) || /^(SH|HDTN\d*|CHAOCO)$/.test(e.MaMon)) { hong = true; return; }
        var a = huong === 'B' ? sangB : sangA, b = huong === 'B' ? sangA : sangB;
        if (a[e.ID]) return;
        if (b[e.ID]) { hong = true; return; }
        a[e.ID] = { e: e, i: i }; q.push([e, huong, i]);
        if (++dem > 16) { hong = true; return; }
        var cap = self.banCap(e);
        if (cap) {
          var j = viTri(cap, huong === 'B' ? kA : kB);
          if (j >= 0 && j !== i) them(cap, huong, j);
        }
      };
      var dungDo = function (e, k) {
        var out = [];
        var o = self.map[e.MaLop + '|' + k]; if (o && o.ID !== e.ID) out.push(o);
        if (self.laGVThat(e.MaGV, e.MaMon)) (self.gvIdx[e.MaGV + '|' + k] || []).forEach(function (r) { if (r.ID !== e.ID) out.push(r); });
        if (e.MaPhong) (self.phongIdx[e.MaPhong + '|' + k] || []).forEach(function (r) { if (r.ID !== e.ID) out.push(r); });
        return out;
      };
      them(this.map[L + '|' + kA[iT]], 'B', iT);
      if (this.laGVThat(G, m.MaMon)) (this.gvIdx[G + '|' + kA[iT]] || []).forEach(function (r) { them(r, 'B', iT); });
      while (q.length && !hong) {
        var cur = q.shift(), e = cur[0], i = cur[2];
        if (cur[1] === 'B') {
          dungDo(e, kB[i]).forEach(function (r) { if (!sangB[r.ID]) them(r, 'A', i); });
        } else {
          if (i === iT && (e.MaLop === L || (self.laGVThat(e.MaGV, e.MaMon) && e.MaGV === G))) { hong = true; break; }
          dungDo(e, kA[i]).forEach(function (r) { if (!sangA[r.ID]) them(r, 'B', i); });
        }
      }
      if (hong) return null;
      var dat = [];
      Object.keys(sangB).forEach(function (id) { dat.push(self.datCua(sangB[id].e, B[sangB[id].i])); });
      Object.keys(sangA).forEach(function (id) { dat.push(self.datCua(sangA[id].e, A[sangA[id].i])); });
      return dat;
    },
    // Muc nang cua luu y (de xep hang phuong an).
    diemLuuY: function (soft) {
      return soft.reduce(function (s, w) {
        if (/báo bận/.test(w)) return s + 5;
        if (/Tách cặp|tiết đôi/.test(w)) return s + 3;
        if (/tiết\/ngày|Sinh hoạt/.test(w)) return s + 2;
        return s + 1;
      }, 0);
    },
    // Tat ca phuong an cho 1 tiet thieu m: Kempe (sach / co luu y) + pha luat hop. Sap: it vuong nhat truoc.
    goiYCho: function (m) {
      var self = this, L = m.MaLop, G = m.MaGV, khoi = this.khoiCua(L), ds = [], daCo = {};
      var oLop = [];
      this.thuCols.forEach(function (thu) {
        self.slots.forEach(function (s) {
          if (khoi === 'KHAC' || self.slotKhoi[khoi + '|' + thu + '|' + s.Buoi + '|' + s.Tiet]) oLop.push({ Thu: thu, Buoi: s.Buoi, Tiet: s.Tiet });
        });
      });
      var hopLeO = function (o) { return khoi === 'KHAC' || !!self.slotKhoi[khoi + '|' + o.Thu + '|' + o.Buoi + '|' + o.Tiet]; };
      var cap2 = [];
      oLop.forEach(function (o) { var n2 = { Thu: o.Thu, Buoi: o.Buoi, Tiet: o.Tiet + 1 }; if (hopLeO(n2)) cap2.push([o, n2]); });
      var datThem = function (t) { return { item: null, MaLop: L, MaMon: m.MaMon, MaGV: G, MaPhong: self.phongMD(L, m.MaMon), TenMon: m.TenMon, TenGV: m.HoTen, to: t }; };
      var them = function (pa) {
        var sig = pa.dat.map(function (d) { return (d.item ? d.item.ID : 'm') + '>' + d.to.Thu + d.to.Buoi + d.to.Tiet; }).sort().join(',') + (pa.hop ? '#h' : '');
        if (daCo[sig]) return;
        daCo[sig] = true; ds.push(pa);
      };
      var tenM = (m.TenMon || m.MaMon) + ' ' + L;
      oLop.forEach(function (t) {
        var kT = t.Thu + '|' + t.Buoi + '|' + t.Tiet;
        var gvRows = self.laGVThat(G, m.MaMon) ? (self.gvIdx[G + '|' + kT] || []) : [];
        var hop = gvRows.some(function (r) { return r.MaMon === 'HOP'; });
        var B = self.map[L + '|' + kT];
        if (!hop) {
          if (!B && !gvRows.length) {
            var kt0 = self.kiemTra([datThem(t)], false, true);
            if (!kt0.hard) them({ loai: kt0.soft.length ? 'luuy' : 'sach', dat: [datThem(t)], soft: kt0.soft, diem: self.diemLuuY(kt0.soft), soTiet: 0,
              text: 'Xếp ' + tenM + ' thẳng vào ' + self.nhanO(t.Thu, t.Buoi, t.Tiet) });
          } else {
            var thuChuoi = function (A, B, iT) {
              var ch = self.chuoiKempe(m, A, B, iT);
              if (!ch || !ch.length) return;
              var dat = ch.concat([datThem(t)]);
              var kt = self.kiemTra(dat, false, true);
              if (kt.hard) return;
              var lop = {}, gv = {};
              ch.forEach(function (d) { lop[d.MaLop] = 1; if (self.laGVThat(d.MaGV, d.MaMon)) gv[d.MaGV] = 1; });
              var nh = function (S) { return self.nhanO(S[0].Thu, S[0].Buoi, S[0].Tiet) + (S.length > 1 ? '–' + S[S.length - 1].Tiet : ''); };
              them({ loai: kt.soft.length ? 'luuy' : 'sach', dat: dat, soft: kt.soft, diem: self.diemLuuY(kt.soft), soTiet: ch.length,
                soLop: Object.keys(lop).length, soGV: Object.keys(gv).length,
                text: 'Đổi giờ ' + nh(A) + ' ↔ ' + nh(B) + ' cho ' + ch.length + ' tiết ('
                  + ch.map(function (d) { return d.MaLop + ' ' + d.MaMon; }).join(', ') + '), rồi xếp ' + tenM + ' vào ' + self.nhanO(t.Thu, t.Buoi, t.Tiet) });
            };
            // Doi 1 gio
            oLop.forEach(function (u) {
              if (u.Thu === t.Thu && u.Buoi === t.Buoi && u.Tiet === t.Tiet) return;
              thuChuoi([t], [u], 0);
            });
            // Doi khung 2 gio lien nhau (giu nguyen cap tiet doi)
            [[0, 1], [-1, 0]].forEach(function (lech) {
              var A = lech.map(function (d) { return { Thu: t.Thu, Buoi: t.Buoi, Tiet: t.Tiet + d }; });
              if (!A.every(function (o) { return hopLeO(o); })) return;
              var iT = lech.indexOf(0);
              cap2.forEach(function (B) {
                var trungA = B.some(function (o) { return A.some(function (x) { return x.Thu === o.Thu && x.Buoi === o.Buoi && x.Tiet === o.Tiet; }); });
                if (!trungA) thuChuoi(A, B, iT);
              });
            });
          }
        } else if (!B && gvRows.length === gvRows.filter(function (r) { return r.MaMon === 'HOP'; }).length) {
          // Pha luat: GV vang hop 1 tiet (lop dang trong gio do).
          var kh = self.kiemTra([datThem(t)], true, false);
          them({ loai: 'phaluat', dat: [datThem(t)], soft: kh.soft, diem: self.diemLuuY(kh.soft), soTiet: 0, hop: { MaGV: G, Thu: t.Thu, Buoi: t.Buoi, Tiet: t.Tiet },
            luat: self.tenGV(G) + ' vắng họp 1 tiết',
            text: 'Xếp ' + tenM + ' vào ' + self.nhanO(t.Thu, t.Buoi, t.Tiet) + ' — ' + self.tenGV(G) + ' vắng họp 1 tiết' });
        }
      });
      var hang = { sach: 0, luuy: 1, phaluat: 2 };
      ds.sort(function (a, b) {
        return (hang[a.loai] - hang[b.loai]) || ((a.diem || 0) - (b.diem || 0)) || (a.soTiet - b.soTiet) || ((a.soGV || 0) - (b.soGV || 0));
      });
      return ds.slice(0, 8);
    },
    moGoiY: function (t) {
      this.goiYMuc = t;
      this.goiYDs = this.goiYCho(t);
      this.goiYTatCa = null;
      if (this.xemLop) this.hienLop(t.MaLop); else this.xemLop = t.MaLop;
      if (!this.goiYDs.length) this.msg = { loai: 'loi', text: 'Không tìm được chuỗi hoán đổi 1 cặp giờ cho ' + t.MaLop + ' · ' + t.MaMon + ' — thử khay tạm / kéo thả nhiều bước' };
    },
    xemTruocGoiY: function (pa) {
      this.pending = pa ? { key: 'goiy', lop: '', k: '', plan: { loai: pa.loai === 'sach' ? 'doi' : 'mem', text: pa.text, soft: pa.soft, xung: [], dat: pa.dat } } : null;
    },
    apGoiY: function (pa, muc) {
      var m = muc || this.goiYMuc;
      this.damBaoNhap();
      this.pending = null;
      this.apNhap({ text: pa.text, dat: pa.dat,
        chapNhan: pa.hop ? { id: 'gv' + pa.hop.MaGV + '|' + pa.hop.Thu + '|' + pa.hop.Buoi + '|' + pa.hop.Tiet, val: pa.hop } : null });
      this.goiYDs = []; this.goiYMuc = null;
      if (this.goiYTatCa) this.chayGoiYTatCa();
      if (m && !this.goiYTatCa) this.msg = { loai: 'ok', text: 'Nháp: đã xếp ' + m.MaLop + ' · ' + m.MaMon + ' — kiểm tra rồi bấm Lưu cả chuỗi' };
    },
    chayGoiYTatCa: function () {
      var self = this;
      this.goiYDs = []; this.goiYMuc = null;
      this.goiYTatCa = this.thieuSorted.map(function (t) {
        var ds = self.goiYCho(t);
        return { t: t, best: ds[0] || null, n: ds.length };
      });
    },
    // ---------- nhap lien hoan ----------
    batDauNhap: function () {
      if (this.nhap) return;
      this.nhap = { pos: {}, gvDoi: {}, them: [], xoa: {}, steps: [], nextId: -1, chapNhan: {} };
      this.redoNhap = [];
      this.xacNhanBo = false;
      this.msg = { loai: 'ok', text: 'Đã bật nháp liên hoàn — các nước đi chỉ tạm trên màn hình cho tới khi bấm Lưu cả chuỗi' };
    },
    boNhap: function () {
      if (this.nhap && this.nhap.steps.length && !this.xacNhanBo) { this.xacNhanBo = true; return; }
      this.nhap = null; this.redoNhap = []; this.xacNhanBo = false; this.xacNhanKhay = false; this.anLop = {};
      this.boChon();
      this.msg = { loai: 'ok', text: 'Đã bỏ nháp, dữ liệu giữ nguyên như trước' };
    },
    // Ghi 1 vi tri moi cho 1 dong (that hoac ao) vao nhap, tra ve ban ghi de hoan tac.
    datViTri: function (it, to) {
      var n = this.nhap;
      if (it.ao) {
        var v = n.them.filter(function (x) { return x.ID === it.ID; })[0];
        var cu = { Thu: v.Thu, Buoi: v.Buoi, Tiet: v.Tiet, khay: !!v.khay, tu: v.tu || null };
        if (to.khay) { v.tu = v.khay ? v.tu : { Thu: v.Thu, Buoi: v.Buoi, Tiet: v.Tiet }; v.khay = true; }
        else { v.Thu = to.Thu; v.Buoi = to.Buoi; v.Tiet = to.Tiet; v.khay = false; }
        return { kind: 'aoPos', ID: it.ID, prev: cu };
      }
      var prev = n.pos[it.ID] ? Object.assign({}, n.pos[it.ID]) : null;
      var goc = this.itemsById[it.ID];
      if (to.khay) {
        // Nho vi tri hien tai (truoc khi nhac ra) de "tra ve cho cu".
        var tu = it.khay ? it.tu : { Thu: it.Thu, Buoi: it.Buoi, Tiet: it.Tiet };
        n.pos[it.ID] = { khay: true, tu: tu, Thu: 0, Buoi: '', Tiet: 0 };
      } else if (goc && goc.Thu === to.Thu && goc.Buoi === to.Buoi && goc.Tiet === to.Tiet) delete n.pos[it.ID];
      else n.pos[it.ID] = { Thu: to.Thu, Buoi: to.Buoi, Tiet: to.Tiet };
      return { kind: 'pos', ID: it.ID, prev: prev };
    },
    apNhap: function (p, laRedo) {
      if (!p || !p.dat) return;
      var n = this.nhap, self = this, ghi = [];
      p.dat.forEach(function (d) {
        if (d.item) ghi.push(self.datViTri(d.item, d.to));
        else {
          var id = n.nextId--;
          var t = self.sel && self.sel.kind === 'thieu' ? self.sel.t : {};
          n.them.push({ ID: id, MaLop: d.MaLop, MaMon: d.MaMon, MaGV: d.MaGV, TenMon: d.TenMon || t.TenMon || d.MaMon, TenGV: d.TenGV || t.HoTen || self.tenGV(d.MaGV),
                        Thu: d.to.Thu, Buoi: d.to.Buoi, Tiet: d.to.Tiet, MaPhong: d.MaPhong || self.phongMD(d.MaLop, d.MaMon), DaKhoa: false });
          ghi.push({ kind: 'them', ID: id });
        }
      });
      if (p.chapNhan) { n.chapNhan[p.chapNhan.id] = p.chapNhan.val; ghi.push({ kind: 'chapNhan', ID: 0, id: p.chapNhan.id }); }
      n.steps.push({ desc: p.text, ghi: ghi, lai: { type: 'plan', p: p } });
      if (!laRedo) this.redoNhap = [];
      this.pending = null;
      this.boChon();
      this.msg = { loai: 'ok', text: 'Nháp: ' + p.text };

    },
    hoanTacBuoc: function (st) {
      var n = this.nhap;
      for (var i = st.ghi.length - 1; i >= 0; i--) {
        var g = st.ghi[i];
        if (g.kind === 'pos') { if (g.prev) n.pos[g.ID] = g.prev; else delete n.pos[g.ID]; }
        else if (g.kind === 'aoPos') { var v = n.them.filter(function (x) { return x.ID === g.ID; })[0]; if (v) Object.assign(v, g.prev); }
        else if (g.kind === 'them') { n.them = n.them.filter(function (x) { return x.ID !== g.ID; }); }
        else if (g.kind === 'gv') { if (g.ao) { var a = n.them.filter(function (x) { return x.ID === g.ID; })[0]; if (a) { a.MaGV = g.prev.MaGV; a.TenGV = g.prev.TenGV; } } else if (g.prev) n.gvDoi[g.ID] = g.prev; else delete n.gvDoi[g.ID]; }
        else if (g.kind === 'xoa') { if (g.ao) n.them.push(g.row); else delete n.xoa[g.ID]; }
        else if (g.kind === 'chapNhan') { delete n.chapNhan[g.id]; }
      }
    },
    hoanTacNhap: function () {
      var n = this.nhap;
      if (!n || !n.steps.length) return;
      var st = n.steps.pop();
      this.hoanTacBuoc(st);
      this.redoNhap.push(st);
      this.boChon();
      this.msg = { loai: 'ok', text: 'Nháp: hoàn tác — ' + st.desc };
    },
    lamLaiNhap: function () {
      if (!this.nhap || !this.redoNhap.length) return;
      var st = this.redoNhap.pop(), self = this;
      if (st.lai.type === 'plan') {
        // Tim lai dong hieu luc theo ID (vi tri hien tai) roi ap lai dung nuoc do.
        var p = Object.assign({}, st.lai.p, { dat: st.lai.p.dat.map(function (d) {
          if (!d.item) return d;
          var cur = self.itemsHL.concat(self.khayItems).filter(function (r) { return r.ID === d.item.ID; })[0];
          return Object.assign({}, d, { item: cur || d.item });
        }) });
        this.apNhap(p, true);
      } else if (st.lai.type === 'gv') {
        this.apGVNhap(st.lai.rows, st.lai.c, st.desc, true);
      } else if (st.lai.type === 'xoa') {
        this.apXoaNhap(st.lai.it, st.desc, true);
      }
    },
    apGVNhap: function (rows, c, desc, laRedo) {
      var n = this.nhap, self = this, ghi = [];
      rows.forEach(function (r) {
        if (r.ao) {
          var a = n.them.filter(function (x) { return x.ID === r.ID; })[0];
          ghi.push({ kind: 'gv', ID: r.ID, ao: true, prev: { MaGV: a.MaGV, TenGV: a.TenGV } });
          a.MaGV = c.MaGV; a.TenGV = c.Ten;
        } else {
          ghi.push({ kind: 'gv', ID: r.ID, prev: n.gvDoi[r.ID] ? Object.assign({}, n.gvDoi[r.ID]) : null });
          var goc = self.itemsById[r.ID];
          if (goc && goc.MaGV === c.MaGV) delete n.gvDoi[r.ID];
          else n.gvDoi[r.ID] = { MaGV: c.MaGV, TenGV: c.Ten };
        }
      });
      n.steps.push({ desc: desc, ghi: ghi, lai: { type: 'gv', rows: rows, c: c } });
      if (!laRedo) this.redoNhap = [];
      this.boChon();
      this.msg = { loai: 'ok', text: 'Nháp: ' + desc };
    },
    apXoaNhap: function (it, desc, laRedo) {
      var n = this.nhap, ghi = [];
      if (it.ao) {
        var row = n.them.filter(function (x) { return x.ID === it.ID; })[0];
        n.them = n.them.filter(function (x) { return x.ID !== it.ID; });
        ghi.push({ kind: 'xoa', ID: it.ID, ao: true, row: row });
      } else {
        n.xoa[it.ID] = true;
        ghi.push({ kind: 'xoa', ID: it.ID });
      }
      n.steps.push({ desc: desc, ghi: ghi, lai: { type: 'xoa', it: it } });
      if (!laRedo) this.redoNhap = [];
      this.boChon();
      this.msg = { loai: 'ok', text: 'Nháp: ' + desc };
    },
    // Chon 1 tiet trong xung dot de go (chuyen sang ban sap lop do neu dang mo ban sap).
    goXung: function (r) {
      var cur = this.itemsHL.filter(function (x) { return x.ID === r.ID; })[0] || r;
      if (this.xemLop) this.hienLop(cur.MaLop);
      this.chonTiet(cur, true);
    },
    // Luu ca chuoi: gop cac thay doi rong cua nhap thanh 1 thao tac (1 giao dich phia may chu).
    luuNhap: function () {
      var n = this.nhap, self = this;
      if (!n || this.dangGui) return;
      if (this.xungDot.length) { this.msg = { loai: 'loi', text: 'Còn ' + this.xungDot.length + ' xung đột — gỡ hết rồi mới lưu được' }; return; }
      if (this.khayItems.length && !this.xacNhanKhay) { this.xacNhanKhay = true; return; }
      this.xacNhanKhay = false;
      var moves = [], invMoves = [], gv = [], invGv = [], del = [], invAdds = [], adds = [];
      var khayDel = {};
      Object.keys(n.pos).forEach(function (id) {
        id = +id;
        if (n.xoa[id]) return;
        var goc = self.itemsById[id], p = n.pos[id];
        if (!goc) return;
        if (p.khay) { khayDel[id] = true; return; } // con trong khay khi luu -> go (thanh tiet con thieu)
        moves.push({ ID: id, Thu: p.Thu, Buoi: p.Buoi, Tiet: p.Tiet });
        invMoves.push({ ID: id, Thu: goc.Thu, Buoi: goc.Buoi, Tiet: goc.Tiet });
      });
      Object.keys(n.gvDoi).forEach(function (id) {
        id = +id;
        if (n.xoa[id]) return;
        var goc = self.itemsById[id];
        if (!goc) return;
        gv.push({ ID: id, MaGV: n.gvDoi[id].MaGV });
        invGv.push({ ID: id, MaGV: goc.MaGV });
      });
      var delOld = [];
      Object.keys(n.xoa).concat(Object.keys(khayDel)).forEach(function (id) {
        id = +id;
        var goc = self.itemsById[id];
        if (!goc) return;
        del.push(id); delOld.push(id);
        invAdds.push({ MaLop: goc.MaLop, MaMon: goc.MaMon, MaGV: goc.MaGV, Thu: goc.Thu, Buoi: goc.Buoi, Tiet: goc.Tiet, MaPhong: goc.MaPhong || null });
      });
      n.them.forEach(function (r) {
        if (r.khay) return;
        adds.push({ MaLop: r.MaLop, MaMon: r.MaMon, MaGV: r.MaGV, Thu: r.Thu, Buoi: r.Buoi, Tiet: r.Tiet, MaPhong: r.MaPhong || null });
      });
      if (!moves.length && !gv.length && !del.length && !adds.length) { this.nhap = null; this.boChon(); this.msg = { loai: 'ok', text: 'Nháp không có thay đổi nào' }; return; }
      var ops = { moves: moves, gv: gv, del: del, adds: adds };
      var hop = Object.keys(n.chapNhan || {}).map(function (k) { return n.chapNhan[k]; });
      if (hop.length) ops.choPhepHop = hop;
      var inv = { moves: invMoves, gv: invGv, adds: invAdds, del: [] };
      var desc = 'Chuỗi ' + n.steps.length + ' bước: ' + n.steps.map(function (s) { return s.desc; }).join(' → ');
      this.gui(ops, desc, inv, { laNhap: true, soThem: adds.length, delOldIDs: delOld });
    },
    // ---------- thao tac ----------
    chonTiet: function (it, cuon) {
      if (this.xemLop && this.bsLops.indexOf(it.MaLop) < 0) this.hienLop(it.MaLop);
      this.sel = { kind: 'tiet', item: it };
      this.pending = null; this.xacNhanGo = false; this.moDoiGV = false; this.msg = null;
      if (this.laGVThat(it.MaGV, it.MaMon)) this.focusGV = it.MaGV;
      if (cuon && !this.xemLop) this.cuonToiLop(it.MaLop);
    },
    // moBanSap: bam muc "con thieu" -> mo luon ban sap cua lop do (de nhin lich lop + lich GV).
    chonThieu: function (t, moBanSap) {
      if (this.xemLop) this.hienLop(t.MaLop);
      else if (moBanSap) this.xemLop = t.MaLop;
      this.sel = { kind: 'thieu', t: t };
      this.pending = null; this.xacNhanGo = false; this.moDoiGV = false; this.msg = null;
      if (this.laGVThat(t.MaGV, t.MaMon)) this.focusGV = t.MaGV;
      if (!this.xemLop) this.cuonToiLop(t.MaLop);
    },
    boChon: function () {
      this.sel = null; this.pending = null; this.xacNhanGo = false; this.moDoiGV = false; this.goiYNhap = null;
    },
    cuonToiLop: function (lop) {
      var self = this;
      if (this.chiThieu === false && this.cap !== 'all' && this.capCua(lop) !== this.cap) this.cap = 'all';
      if (this.dong[this.khoiCua(lop)]) this.toggleNhom(this.khoiCua(lop));
      this.$nextTick(function () {
        var el = self.$el.querySelector('tr[data-lop="' + lop + '"]');
        if (el && el.scrollIntoView) el.scrollIntoView({ block: 'center', behavior: 'smooth' });
      });
    },
    onHover: function (lop, c) {
      if (this.sel && lop === this.selLop) this.hoverKey = lop + '|' + c.k;
    },
    onDragStart: function (c) {
      if (c.it && this.diChuyenDuoc(c.it)) this.chonTiet(c.it, false);
    },
    onDbl: function (c) {
      if (c.it && this.diChuyenDuoc(c.it)) this.$emit('edit-cell', c.it);
    },
    onClick: function (lop, c) {
      if (this.dangGui) return;
      var thu = c.thu, s = c.s, it = c.it;
      var key = lop + '|' + thu + '|' + s.Buoi + '|' + s.Tiet;
      // Dang chon va bam vao o cua cung lop -> nuoc di
      if (this.sel && lop === this.selLop) {
        var p = this.plans[thu + '|' + s.Buoi + '|' + s.Tiet];
        if (!p || p.loai === 'chon') { this.boChon(); return; }
        // O khong di toi duoc nhung co tiet -> hieu la nguoi dung muon chon tiet do.
        if (p.loai === 'cam' && it && this.diChuyenDuoc(it)) { this.chonTiet(it, false); return; }
        if (p.loai === 'cam') { this.msg = { loai: 'loi', text: p.text }; this.goiYNhap = p.nhapAlt || null; return; }
        if (p.loai === 'chuyen' || p.loai === 'doi') { this.thucHien(p); return; }
        if (this.pending && this.pending.key === key) { this.thucHien(p); return; }
        this.pending = { key: key, lop: lop, k: c.k, plan: p };
        return;
      }
      if (it && this.diChuyenDuoc(it)) { this.chonTiet(it, false); return; }
      if (it) { this.msg = { loai: 'loi', text: 'Ô này là giờ học nhóm / khoá phòng — không di chuyển ở đây' }; return; }
      // O trong, chua chon gi: neu lop con thieu -> chon tiet thieu dau tien cua lop do.
      var t = this.thieuHL.filter(function (x) { return x.MaLop === lop; })[0];
      if (t) { this.chonThieu(t); this.hoverKey = key; }
      else this.boChon();
    },
    gui: function (ops, desc, inv, extra) {
      this.seq += 1;
      this.dangGui = Object.assign({ seq: this.seq, desc: desc, ops: ops, inv: inv, isUndo: false }, extra || {});
      this.msg = null;
      this.pending = null;
      this.$emit('apply', { ops: ops, seq: this.seq });
    },
    thucHien: function (p) {
      if (!p || !p.dat) return;
      if (this.nhap) { this.apNhap(p); return; }
      var moves = [], inv = [], add = null;
      p.dat.forEach(function (d) {
        if (d.item) {
          moves.push({ ID: d.item.ID, Thu: d.to.Thu, Buoi: d.to.Buoi, Tiet: d.to.Tiet });
          inv.push({ ID: d.item.ID, Thu: d.item.Thu, Buoi: d.item.Buoi, Tiet: d.item.Tiet });
        } else {
          add = { MaLop: d.MaLop, MaMon: d.MaMon, MaGV: d.MaGV, Thu: d.to.Thu, Buoi: d.to.Buoi, Tiet: d.to.Tiet, MaPhong: d.MaPhong || null };
        }
      });
      var ops = { moves: moves };
      if (add) ops.add = add;
      this.gui(ops, p.text, { moves: inv }, { themMoi: !!add });
    },
    goTiet: function () { this.xacNhanGo = true; this.moDoiGV = false; },
    thucHienGo: function () {
      var it = this.sel.item;
      this.xacNhanGo = false;
      if (this.nhap) { this.apXoaNhap(it, 'Gỡ ' + it.MaMon + ' lớp ' + it.MaLop + ' (' + this.nhanO(it.Thu, it.Buoi, it.Tiet) + ')'); return; }
      this.gui({ del: [it.ID] }, 'Gỡ ' + it.MaMon + ' lớp ' + it.MaLop + ' (' + this.nhanO(it.Thu, it.Buoi, it.Tiet) + ')',
        { add: { MaLop: it.MaLop, MaMon: it.MaMon, MaGV: it.MaGV, Thu: it.Thu, Buoi: it.Buoi, Tiet: it.Tiet, MaPhong: it.MaPhong || null } },
        { delOldIDs: [it.ID] });
    },
    doiGV: function (c) {
      var it = this.sel.item, cap = this.capDoi;
      var rows = [it].concat(cap ? [cap] : []);
      this.moDoiGV = false;
      if (this.nhap) { this.apGVNhap(rows, c, 'Đổi GV ' + it.MaMon + ' lớp ' + it.MaLop + (cap ? ' (cả cặp)' : '') + ': ' + (it.TenGV || it.MaGV) + ' → ' + c.Ten); return; }
      this.gui({ gv: rows.map(function (r) { return { ID: r.ID, MaGV: c.MaGV }; }) },
        'Đổi GV ' + it.MaMon + ' lớp ' + it.MaLop + (cap ? ' (cả cặp)' : '') + ': ' + (it.TenGV || it.MaGV) + ' → ' + c.Ten,
        { gv: rows.map(function (r) { return { ID: r.ID, MaGV: r.MaGV }; }) });
    },
    hoanTac: function () {
      if (!this.undo.length || this.dangGui) return;
      var e = this.undo[this.undo.length - 1];
      this.seq += 1;
      this.dangGui = { seq: this.seq, desc: e.desc, isUndo: true };
      this.msg = null;
      this.boChon();
      this.$emit('apply', { ops: e.inv, seq: this.seq });
    },
    lamLai: function () {
      if (!this.redo.length || this.dangGui) return;
      var e = this.redo[this.redo.length - 1];
      this.seq += 1;
      this.dangGui = { seq: this.seq, desc: e.desc, isRedo: true };
      this.msg = null;
      this.boChon();
      this.$emit('apply', { ops: e.ops, seq: this.seq });
    },
    // Doi ID cu -> moi trong moi buoc da luu (hoan tac + lam lai), ca thao tac xuoi lan nguoc.
    doiID: function (cu, moi) {
      var va = function (o) {
        if (!o) return;
        (o.moves || []).forEach(function (m) { if (m.ID === cu) m.ID = moi; });
        (o.gv || []).forEach(function (m) { if (m.ID === cu) m.ID = moi; });
        if (o.del) o.del = o.del.map(function (x) { return x === cu ? moi : x; });
      };
      this.undo.concat(this.redo).forEach(function (e) {
        va(e.ops); va(e.inv);
        if (e.delOldIDs) e.delOldIDs = e.delOldIDs.map(function (x) { return x === cu ? moi : x; });
        if (e.idsThem) e.idsThem = e.idsThem.map(function (x) { return x === cu ? moi : x; });
      });
    },
    onKey: function (e) {
      var tag = (e.target && e.target.tagName) || '';
      if (tag === 'INPUT' || tag === 'TEXTAREA' || (e.target && e.target.isContentEditable)) return;
      if (document.querySelector('.v-overlay--active')) return; // dang mo hop thoai
      if (e.key === 'Escape') { if (this.pending) this.pending = null; else if (this.nhomIds.length) this.nhomIds = []; else this.boChon(); }
      else if ((e.key === 'Delete' || e.key === 'Backspace') && this.nhomItems.length && !this.sel) { e.preventDefault(); var self = this, nh = this.nhomItems.slice(); this.damBaoNhap(); this.apNhap({ text: 'Nhấc nhóm ' + nh.length + ' tiết ra khay', dat: nh.map(function (r) { return self.datCua(r, { khay: true }); }) }); this.nhomIds = []; }
      else if ((e.key === 'Delete' || e.key === 'Backspace') && this.sel && this.sel.kind === 'tiet' && !this.sel.item.khay) { e.preventDefault(); this.duaRaKhay(this.sel.item); }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'y' || e.key === 'Y' || (e.shiftKey && (e.key === 'z' || e.key === 'Z')))) { e.preventDefault(); if (this.nhap) this.lamLaiNhap(); else this.lamLai(); }
      else if ((e.ctrlKey || e.metaKey) && (e.key === 'z' || e.key === 'Z')) { e.preventDefault(); if (this.nhap) this.hoanTacNhap(); else this.hoanTac(); }
    }
  }
	}
</script>

<style scoped>
.uc-tt { font-size: 11px; outline: none; }
.uc-tt__bar { display: flex; flex-wrap: wrap; align-items: center; gap: 8px; margin-bottom: 4px; }
.uc-tt__chips { display: flex; gap: 4px; flex-wrap: wrap; }
.uc-tt__chip { border: 1px solid #c8c8c8; border-radius: 12px; padding: 1px 9px; background: #fff; font-size: 11px; cursor: pointer; }
.uc-tt__chip--on { background: #2e7d32; border-color: #2e7d32; color: #fff; }
.uc-tt__chip-n { opacity: 0.7; font-size: 10px; }
.uc-tt__search { border: 1px solid #c8c8c8; border-radius: 4px; padding: 2px 6px; font-size: 11px; width: 190px; background: #fff; }
.uc-tt__chk { display: flex; align-items: center; gap: 3px; cursor: pointer; }
.uc-tt__sum { color: #555; margin-left: auto; }
.uc-tt__red { color: #c62828; }
.uc-tt__green { color: #2e7d32; }
.uc-tt__muted { color: #777; }
/* Bang dieu khien nuoc di */
.uc-tt__panel { border: 1px solid #d0d7de; border-radius: 4px; background: #fbfcfd; padding: 4px 8px; margin-bottom: 4px; }
.uc-tt__panel--loi { border-color: #e57373; }
.uc-tt__prow { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; min-height: 22px; }
.uc-tt__ptitle { font-weight: 700; color: #2e7d32; text-transform: uppercase; font-size: 10px; letter-spacing: 0.4px; }
.uc-tt__plabel { color: #555; font-weight: 600; }
.uc-tt__pinfo { font-size: 12px; }
.uc-tt__tag { display: inline-block; margin-left: 4px; padding: 0 5px; border-radius: 8px; background: #fff3e0; color: #e65100; font-size: 10px; }
.uc-tt__sp { flex: 1 1 auto; }
.uc-tt__btn { border: 1px solid #c8c8c8; background: #fff; border-radius: 4px; padding: 1px 8px; font-size: 11px; cursor: pointer; }
.uc-tt__btn:hover:not(:disabled) { background: #f1f5f9; }
.uc-tt__btn:disabled { opacity: 0.45; cursor: default; }
.uc-tt__btn--pri { background: #2e7d32; border-color: #2e7d32; color: #fff; }
.uc-tt__btn--pri:hover:not(:disabled) { background: #1b5e20; }
.uc-tt__btn--danger { background: #c62828; border-color: #c62828; color: #fff; }
.uc-tt__tchip { border: 1px solid #ef9a9a; background: #fff5f5; color: #b71c1c; border-radius: 10px; padding: 0 7px; font-size: 10.5px; cursor: pointer; }
.uc-tt__tchip:hover { background: #ffebee; }
.uc-tt__legend { gap: 12px; color: #444; }
.uc-tt__lg { display: inline-block; width: 11px; height: 11px; border-radius: 2px; vertical-align: -1px; margin-right: 3px; border: 1px solid rgba(0, 0, 0, 0.15); }
.uc-tt__desc { background: #fff; border-top: 1px dashed #d0d7de; margin-top: 2px; padding-top: 2px; }
.uc-tt__dot { display: inline-block; width: 10px; height: 10px; border-radius: 50%; }
.uc-tt__warn { color: #e65100; }
.uc-tt__doigv { border-top: 1px dashed #d0d7de; margin-top: 2px; padding-top: 3px; }
.uc-tt__gvlist { display: flex; flex-wrap: wrap; gap: 4px; margin-top: 3px; max-height: 120px; overflow-y: auto; }
.uc-tt__gvopt { display: flex; flex-direction: column; align-items: flex-start; border: 1px solid #c8e6c9; background: #f1f8e9; border-radius: 4px; padding: 2px 6px; font-size: 10.5px; cursor: pointer; min-width: 140px; text-align: left; }
.uc-tt__gvopt span { color: #555; font-size: 10px; }
.uc-tt__gvopt--bao-ban { border-color: #ffcc80; background: #fff8e1; }
.uc-tt__gvopt--ban-day { border-color: #e0e0e0; background: #f5f5f5; opacity: 0.6; cursor: not-allowed; }
.uc-tt__gvopt:hover:not(:disabled) { filter: brightness(0.96); }
/* Luoi */
.uc-tt__wrap { overflow: auto; max-height: 70vh; border: 1px solid #d0d0d0; }
.uc-tt__table { border-collapse: separate; border-spacing: 0; }
.uc-tt__table th, .uc-tt__table td { border-right: 1px solid #e3e3e3; border-bottom: 1px solid #e3e3e3; text-align: center; padding: 0; white-space: nowrap; }
.uc-tt__table thead th { position: sticky; background: #f5f5f5; font-weight: 600; z-index: 2; }
.uc-tt__table thead tr:first-child th { top: 0; height: 20px; }
.uc-tt__table thead tr:nth-child(2) th { top: 20px; height: 18px; font-size: 9px; color: #666; }
.uc-tt__table thead tr.uc-tt__gvrow th { top: 38px; height: 22px; font-weight: 400; font-size: 9px; }
.uc-tt__sticky { position: sticky; left: 0; z-index: 1; background: #fafafa; }
.uc-tt__table thead th.uc-tt__sticky { z-index: 3; }
.uc-tt__lophead { min-width: 64px; max-width: 64px; width: 64px; }
.uc-tt__lop { min-width: 64px; max-width: 64px; width: 64px; }
.uc-tt__sticky2 { position: sticky; left: 64px; z-index: 1; background: #fafafa; border-right: 2px solid #9e9e9e !important; }
.uc-tt__table thead th.uc-tt__sticky2 { z-index: 3; }
.uc-tt__dmhead { min-width: 92px; max-width: 92px; }
.uc-tt__dm { min-width: 92px; max-width: 92px; font-size: 10px; cursor: pointer; overflow: hidden; text-overflow: ellipsis; text-align: left !important; padding: 0 3px !important; }
.uc-tt__dm--du { color: #2e7d32; }
.uc-tt__dm--thieu { color: #c62828; font-weight: 600; }
.uc-tt__dmmon { font-weight: 400; font-size: 9px; }
.uc-tt__thu { border-left: 2px solid #9e9e9e !important; }
.uc-tt__daystart { border-left: 2px solid #9e9e9e !important; }
.uc-tt__chieu { background-image: linear-gradient(rgba(0, 0, 0, 0.025), rgba(0, 0, 0, 0.025)); }
.uc-tt__grow td { background: #eef3ee; font-weight: 600; cursor: pointer; text-align: left; padding: 2px 6px; }
.uc-tt__gfill { color: #666; font-weight: 400 !important; }
.uc-tt__lop { font-weight: 600; cursor: pointer; text-align: left !important; padding: 0 4px !important; }
.uc-tt__lop--thieu { color: #c62828; }
.uc-tt__row--sel td.uc-tt__lop, .uc-tt__row--sel td.uc-tt__dm { background: #e3f2fd; }
.uc-tt__badge { background: #e53935; color: #fff; border-radius: 8px; padding: 0 4px; margin-left: 3px; font-size: 9px; }
.uc-tt__cell { min-width: 34px; max-width: 34px; height: 20px; font-size: 9px; overflow: hidden; text-overflow: ellipsis; cursor: pointer; background: #fff; }
.uc-tt__cell--ca { height: 28px; min-width: 40px; max-width: 40px; line-height: 1.1; }
.uc-tt__l1 { font-weight: 700; font-size: 9px; overflow: hidden; text-overflow: ellipsis; }
.uc-tt__l2 { font-size: 8.5px; color: #555; overflow: hidden; text-overflow: ellipsis; }
.uc-tt__l2:hover { color: #1565c0; text-decoration: underline; }
.uc-tt__cell:hover { outline: 2px solid #1976d2; outline-offset: -2px; }
.uc-tt__cell[draggable="true"] { cursor: grab; }
.uc-tt__cell--trong { background: #fcfcfc; }
.uc-tt__m-sh { background: #fff3e0; }
.uc-tt__m-toan { background: #e3f2fd; }
.uc-tt__m-van { background: #e8f5e9; }
.uc-tt__m-anh { background: #e0f2f1; }
.uc-tt__m-khoa { background: #eeeeee; color: #888; }
.uc-tt__cell--khoa { box-shadow: inset 0 -2px 0 #e65100; }
.uc-tt__cell--trung { background: #ffcdd2 !important; color: #b71c1c; font-weight: 700; }
.uc-tt__cell--hit { background: #ffeb3b !important; font-weight: 700; }
.uc-tt__cell--mo { color: #c8c8c8; background: #fafafa !important; }
.uc-tt__cell--gv { box-shadow: inset 0 0 0 2px #7b1fa2; }
/* Mau nuoc di (o cua lop dang chon) */
.uc-tt__n-chuyen { background: #a5d6a7 !important; }
.uc-tt__n-doi { background: #90caf9 !important; }
.uc-tt__n-day { background: #fff59d !important; }
.uc-tt__n-mem { background: #ffcc80 !important; }
.uc-tt__n-cam { background: #eceff1 !important; color: #9e9e9e; cursor: not-allowed; }
.uc-tt__n-chon, .uc-tt__cell--sel { background: #1565c0 !important; color: #fff !important; }
.uc-tt__n-chon .uc-tt__l2, .uc-tt__cell--sel .uc-tt__l2 { color: #e3f2fd; }
.uc-tt__cell--pending { outline: 3px solid #e65100 !important; outline-offset: -3px; }
.uc-tt__cell--phu { outline: 2px dashed #6d4c41 !important; outline-offset: -2px; }
/* Hang lich GV */
.uc-tt__gvhead { text-align: left !important; padding: 0 4px !important; background: #f3e5f5 !important; overflow: hidden; max-width: 156px; }
.uc-tt__gvname { font-weight: 700; color: #6a1b9a; }
.uc-tt__x { border: none; background: none; cursor: pointer; font-size: 13px; line-height: 1; color: #6a1b9a; float: right; }
.uc-tt__gvc { min-width: 34px; cursor: default; }
.uc-tt__gvc--day { background: #e1bee7 !important; color: #4a148c; font-weight: 700 !important; cursor: pointer; }
.uc-tt__gvc--ban { background: repeating-linear-gradient(135deg, #ffe0b2, #ffe0b2 4px, #fff3e0 4px, #fff3e0 8px) !important; color: #e65100; }
.uc-tt__gvc--ranh { background: #f1f8e9 !important; }
.uc-tt__empty { padding: 24px; color: #888; }
/* ===== Bo cuc: toan truong (panel tren) / ban sap lop (panel phai) ===== */
.uc-tt__layout { display: flex; flex-direction: column; }
.uc-tt__layout--bs { flex-direction: row; align-items: flex-start; gap: 10px; }
.uc-tt__layout--bs > .uc-tt__panel { flex: 0 0 340px; position: sticky; top: 4px; max-height: calc(100vh - 120px); overflow-y: auto; margin-bottom: 0; }
.uc-tt__layout--bs .uc-tt__prow { gap: 5px; }
.uc-tt__warn { color: #e65100; padding-left: 16px; }
.uc-tt__hist { border-top: 1px dashed #d0d7de; margin-top: 4px; padding-top: 3px; }
.uc-tt__histrow { font-size: 10.5px; color: #444; padding: 1px 0; border-bottom: 1px dotted #eee; }
.uc-tt__histrow--redo { color: #9e9e9e; font-style: italic; }
.uc-bs__main { flex: 1 1 auto; min-width: 0; }
.uc-bs__top { display: flex; align-items: center; gap: 6px; margin-bottom: 4px; }
.uc-bs__sel { border: 1px solid #c8c8c8; border-radius: 4px; padding: 2px 6px; font-size: 13px; font-weight: 700; background: #fff; }
.uc-bs__dmsum { margin-left: 8px; font-size: 12px; }
.uc-bs__dm { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 6px; }
.uc-bs__dmchip { border: 1px solid #c8e6c9; background: #f1f8e9; border-radius: 10px; padding: 0 8px; font-size: 10.5px; cursor: pointer; }
.uc-bs__dmchip--thieu { border-color: #e57373; background: #ffebee; color: #b71c1c; font-weight: 600; }
.uc-bs__grid { border-collapse: collapse; width: 100%; table-layout: fixed; }
.uc-bs__grid th, .uc-bs__grid td { border: 1px solid #d6d6d6; text-align: center; vertical-align: middle; padding: 2px 3px; }
.uc-bs__grid thead th { background: #f5f5f5; font-size: 11.5px; font-weight: 600; height: 22px; }
.uc-bs__corner { width: 64px; font-size: 10.5px !important; }
.uc-bs__rowhead { background: #fafafa; font-size: 10.5px; font-weight: 600; white-space: nowrap; }
.uc-bs__chieu1 td, .uc-bs__chieu1 th { border-top: 3px solid #9e9e9e !important; }
.uc-bs__cell { height: 42px; cursor: pointer; position: relative; background: #fff; overflow: hidden; }
.uc-bs__cell:hover { outline: 2px solid #1976d2; outline-offset: -2px; }
.uc-bs__cell--trong { background: #fcfcfc; }
.uc-bs__cell--ngoai { background: repeating-linear-gradient(135deg, #f5f5f5, #f5f5f5 5px, #eeeeee 5px, #eeeeee 10px); cursor: default; }
.uc-bs__cell--ngoai:hover { outline: none; }
.uc-bs__mon { font-weight: 700; font-size: 11.5px; color: #1565c0; line-height: 1.2; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.uc-bs__gv { font-size: 10.5px; color: #444; line-height: 1.2; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.uc-bs__lock { position: absolute; top: 0; left: 0; width: 0; height: 0; border-top: 9px solid #e65100; border-right: 9px solid transparent; }
.uc-tt__cell--sel .uc-bs__mon, .uc-tt__cell--sel .uc-bs__gv, .uc-tt__n-chon .uc-bs__mon, .uc-tt__n-chon .uc-bs__gv { color: #fff; }
.uc-bs__gvs { display: flex; gap: 10px; margin-top: 8px; }
.uc-bs__gvbox { flex: 1 1 0; min-width: 0; }
.uc-bs__gvtitle { font-size: 11.5px; margin-bottom: 2px; color: #4a148c; }
.uc-bs__hint { padding: 8px 0; }
.uc-bs__grid--gv td { height: 24px; font-size: 10px; }
.uc-bs__gvc { cursor: default; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.uc-bs__gvc--ranh { background: #e8f5e9; }
.uc-bs__gvc--day { background: #ede7f6; color: #4a148c; cursor: pointer; }
.uc-bs__gvc--lopnay { background: #b39ddb; color: #fff; font-weight: 700; cursor: pointer; }
.uc-bs__gvc--hop { background: #eeeeee; color: #616161; }
.uc-bs__gvc--ban { background: repeating-linear-gradient(135deg, #ffe0b2, #ffe0b2 4px, #fff3e0 4px, #fff3e0 8px); color: #e65100; }
.uc-bs__gvc--hover { outline: 2px solid #1976d2; outline-offset: -2px; }
/* ===== Nhap lien hoan ===== */
.uc-tt__nhap { border: 2px solid #1565c0; border-radius: 4px; background: #e3f2fd; padding: 4px 6px; margin: 3px 0; }
.uc-tt__nhaptitle { font-weight: 800; color: #0d47a1; text-transform: uppercase; font-size: 10.5px; letter-spacing: 0.4px; }
.uc-tt__btn--nhap { background: #1565c0; border-color: #1565c0; color: #fff; }
.uc-tt__btn--nhap:hover:not(:disabled) { background: #0d47a1 !important; }
.uc-tt__xlist { margin-top: 3px; }
.uc-tt__xrow { background: #fff; border-left: 3px solid #d50000; padding: 2px 5px; margin: 2px 0; display: flex; flex-wrap: wrap; gap: 4px; align-items: center; }
.uc-tt__xrow > div { flex: 1 1 100%; color: #b71c1c; }
.uc-tt__xwarn { color: #c2185b; padding-left: 16px; }
.uc-tt__n-xung { background: #f8bbd0 !important; }
.uc-tt__cell--nhap { outline: 2px dashed #1565c0 !important; outline-offset: -3px; }
.uc-tt__cell--xung { box-shadow: inset 0 0 0 3px #d50000 !important; animation: ucTtXung 1s ease-in-out infinite alternate; }
@keyframes ucTtXung { from { box-shadow: inset 0 0 0 3px #d50000; } to { box-shadow: inset 0 0 0 1px #ff8a80; } }
.uc-bs__them2 { font-size: 10px; color: #d50000; font-weight: 700; line-height: 1.1; }
.uc-bs__gvc--xung { box-shadow: inset 0 0 0 3px #d50000; }
/* ===== Khay tam ===== */
.uc-tt__khay { display: flex; flex-wrap: wrap; align-items: center; gap: 6px; min-height: 40px; margin: 8px 0 4px; padding: 5px 8px; border: 2px dashed #90a4ae; border-radius: 6px; background: #fafafa; }
.uc-tt__khay--cho { border-color: #1565c0; background: #e3f2fd; }
.uc-tt__khaywrap { margin-bottom: 4px; }
.uc-tt__khaytitle { font-weight: 800; font-size: 10.5px; text-transform: uppercase; color: #455a64; letter-spacing: 0.4px; margin-right: 4px; }
.uc-tt__kcard { position: relative; display: flex; flex-direction: column; min-width: 150px; padding: 3px 22px 3px 8px; border: 1px solid #ffb74d; border-left: 4px solid #ef6c00; border-radius: 4px; background: #fff8e1; cursor: grab; font-size: 11px; line-height: 1.3; }
.uc-tt__kcard:active { cursor: grabbing; }
.uc-tt__kcard--sel { background: #1565c0; color: #fff; border-color: #0d47a1; }
.uc-tt__kcard--sel .uc-tt__muted { color: #e3f2fd; }
.uc-tt__kback { position: absolute; top: 2px; right: 3px; border: none; background: none; cursor: pointer; font-size: 13px; color: #6d4c41; }
.uc-tt__orange { color: #ef6c00; }
/* ===== Ban sap nhieu lop ===== */
.uc-bs__lops { display: flex; gap: 10px; flex-wrap: wrap; }
.uc-bs__lopbox { flex: 1 1 0; min-width: 0; }
.uc-bs__lops--nhieu .uc-bs__lopbox { flex: 1 1 calc(50% - 10px); max-width: calc(50% - 5px); min-width: 380px; }
.uc-bs__lophead { display: flex; align-items: center; gap: 4px; font-size: 12px; margin-bottom: 2px; }
.uc-bs__lops--nhieu .uc-bs__mon { font-size: 10.5px; }
.uc-bs__lops--nhieu .uc-bs__gv { font-size: 9.5px; }
.uc-bs__lops--nhieu .uc-bs__cell { height: 36px; }
.uc-bs__sel--them { font-weight: 400; font-size: 11.5px; }
/* ===== Gon (de thay nhieu lop) ===== */
.uc-bs__cell { height: 32px !important; padding: 1px 2px !important; }
.uc-bs__mon { font-size: 10.5px !important; }
.uc-bs__gv { font-size: 9.5px !important; }
.uc-bs__grid thead th { height: 18px !important; font-size: 10.5px !important; }
.uc-bs__rowhead { font-size: 9.5px !important; }
.uc-bs__corner { width: 46px !important; }
.uc-bs__lops--nhieu .uc-bs__lopbox { flex: 1 1 calc(33.33% - 10px) !important; max-width: calc(33.33% - 7px) !important; min-width: 300px !important; }
.uc-bs__lops--nhieu .uc-bs__cell { height: 26px !important; }
.uc-bs__lops--nhieu .uc-bs__mon { font-size: 9.5px !important; line-height: 1.1; }
.uc-bs__lops--nhieu .uc-bs__gv { font-size: 8.5px !important; line-height: 1.1; }
.uc-bs__lops--nhieu .uc-bs__grid th, .uc-bs__lops--nhieu .uc-bs__grid td { padding: 0 1px !important; }
.uc-bs__lops--nhieu .uc-bs__corner { width: 34px !important; font-size: 9px !important; }
.uc-bs__lophead { font-size: 11px !important; }
.uc-bs__grid--gv td { height: 18px !important; font-size: 9px !important; }
.uc-bs__gvtitle { font-size: 10.5px !important; }
.uc-bs__dmchip { font-size: 10px !important; }
/* ===== Bang lien doi ===== */
.uc-ld { margin-top: 6px; }
.uc-ld__title { font-size: 11px; margin-bottom: 2px; color: #37474f; }
.uc-ld__wrap { overflow-x: auto; border: 1px solid #cfd8dc; }
.uc-ld__tbl { border-collapse: separate; border-spacing: 0; table-layout: fixed; }
.uc-ld__tbl th, .uc-ld__tbl td { border-right: 1px solid #e0e0e0; border-bottom: 1px solid #e0e0e0; padding: 0 1px !important; text-align: center; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.uc-ld__tbl thead th { background: #f5f5f5; font-size: 9.5px; font-weight: 600; height: 16px; }
.uc-ld__day { border-left: 2px solid #90a4ae !important; }
.uc-ld__slot { width: 30px; min-width: 30px; max-width: 30px; color: #607d8b; font-size: 9px !important; }
.uc-ld__dau { border-left: 2px solid #90a4ae !important; }
.uc-ld__hd { position: sticky; left: 0; z-index: 2; background: #fafafa !important; width: 112px; min-width: 112px; max-width: 112px; text-align: left !important; padding: 0 4px !important; font-size: 10.5px; font-weight: 600; }
.uc-ld__gvname { display: inline-block; max-width: 78px; overflow: hidden; text-overflow: ellipsis; vertical-align: middle; color: #4a148c; font-weight: 600; }
.uc-ld__x { border: none; background: none; cursor: pointer; font-size: 11px; color: #78909c; padding: 0 2px; float: right; line-height: 18px; }
.uc-ld__x:hover { color: #c62828; }
.uc-ld__grp td { background: #eceff1 !important; font-size: 9.5px; font-weight: 700; text-align: left !important; padding: 1px 6px !important; color: #455a64; height: 14px; }
.uc-ld__c { height: 20px !important; width: 30px; min-width: 30px; max-width: 30px; font-size: 9px !important; line-height: 20px; cursor: pointer; }
.uc-ld__tbl .uc-bs__cell { height: 20px !important; padding: 0 1px !important; }
.uc-ld__row--chinh .uc-ld__hd { background: #e3f2fd !important; }
.uc-ld__cot { box-shadow: inset 0 0 0 9999px rgba(25, 118, 210, 0.10); }
th.uc-ld__cot { background: #bbdefb !important; color: #0d47a1; }
/* ===== Nhom Ctrl ===== */
.uc-tt__cell--nhom { box-shadow: inset 0 0 0 3px #1565c0 !important; background-color: #e3f2fd !important; }
/* ===== The lich cung chieu ===== */
.uc-bs__hang { display: flex; gap: 8px; align-items: flex-start; }
.uc-bs__hang > .uc-bs__lops { flex: 0 0 auto; width: 640px; }
.uc-bs__hang > .uc-bs__lops .uc-bs__lopbox { min-width: 0; }
.uc-the__day { flex: 1 1 auto; min-width: 0; display: flex; gap: 6px; overflow-x: auto; padding-bottom: 4px; }
.uc-the { flex: 0 0 auto; border: 1px solid #d6d6d6; border-radius: 4px; background: #fff; }
.uc-the--gv { border-color: #b39ddb; }
.uc-the--phong { border-color: #ef9a9a; }
.uc-the__head { display: flex; align-items: center; gap: 2px; height: 20px; padding: 0 4px; font-size: 11px; font-weight: 600; white-space: nowrap; overflow: hidden; }
.uc-the__ten { max-width: 150px; overflow: hidden; text-overflow: ellipsis; }
.uc-the--gv .uc-the__ten { color: #4a148c; }
.uc-the__tbl { border-collapse: collapse; table-layout: fixed; }
.uc-the__tbl th { height: 20px; font-size: 10px; font-weight: 600; color: #607d8b; background: #f5f5f5; border: 1px solid #e0e0e0; width: 32px; }
.uc-the__tbl td { height: 34px; width: 32px; max-width: 32px; border: 1px solid #e6e6e6; text-align: center; font-size: 9.5px; padding: 0 1px; overflow: hidden; white-space: nowrap; text-overflow: clip; cursor: pointer; }
.uc-the__tbl td.uc-bs__cell { height: 34px !important; }
.uc-the__tbl td.uc-bs__gvc--ranh { background: #f6fbf3 !important; }
.uc-the__tbl td.uc-bs__gvc--day { background: #ede7f6 !important; }
.uc-the__tbl td.uc-bs__gvc--lopnay { background: #b39ddb !important; color: #fff; }
.uc-bs__hang .uc-bs__lophead { height: 20px; margin-bottom: 0; }
.uc-bs__hang .uc-bs__grid thead th { height: 18px !important; }
.uc-tt__n-ok { background: #a5d6a7 !important; }
.uc-tt__n-gan { background: #fff3c4 !important; }
.uc-ld__cot { outline: 2px solid #1976d2 !important; outline-offset: -2px; }
/* ===== Goi y sap ===== */
.uc-tt__goiy { border: 1px solid #c5cae9; border-radius: 4px; background: #fff; padding: 4px 6px; margin: 4px 0; max-height: 55vh; overflow-y: auto; }
.uc-tt__gyrow { border-left: 3px solid #bdbdbd; padding: 3px 6px; margin: 3px 0; background: #fafafa; cursor: default; }
.uc-tt__gyrow:hover { background: #e3f2fd; }
.uc-tt__gyrow--sach { border-left-color: #43a047; }
.uc-tt__gyrow--luuy { border-left-color: #f9a825; }
.uc-tt__gyrow--phaluat { border-left-color: #e53935; }
.uc-tt__gybadge { display: inline-block; padding: 0 6px; border-radius: 8px; font-size: 10px; font-weight: 700; }
.uc-tt__gybadge--sach { background: #e8f5e9; color: #1b5e20; }
.uc-tt__gybadge--luuy { background: #fff8e1; color: #8d6e00; }
.uc-tt__gybadge--phaluat { background: #ffebee; color: #b71c1c; }
.uc-tt__gybadge--khong { background: #eceff1; color: #455a64; }
.uc-bs__phong { display: inline-block; font-size: 10px; line-height: 14px; padding: 0 4px; margin-top: 1px; border-radius: 3px; background: #ede7f6; color: #4527a0; }
.uc-bs__phong--trung { background: #ffebee; color: #b71c1c; font-weight: 600; }
.uc-the__ph { font-size: 9px; line-height: 10px; color: #4527a0; opacity: 0.85; }
</style>
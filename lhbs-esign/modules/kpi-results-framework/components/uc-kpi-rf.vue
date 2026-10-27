<template>
	<div class="uc-kpi-rf">

    <!-- Header -->
    <div class="uc-kpi-rf__top">
      <div>
        <div class="uc-kpi-rf__title">KPI Results Framework · LHBS</div>
        <div class="uc-kpi-rf__subtitle">Báo cáo vận hành tháng 9/2026 · Năm học 2026–2027</div>
      </div>
      <div class="uc-kpi-rf__meta">
        <span>Chốt 30/09/2026</span>
        <span class="uc-kpi-rf__sep">|</span>
        <span title="Dashboard vận hành T9, báo cáo tháng MNTB/MNLK, Báo cáo tổng kết NH 2025–2026">Nguồn: báo cáo T9 các đơn vị, tổng kết NH 2025–26</span>
        <button type="button" :class="['uc-kpi-rf__simbtn', { 'is-solid': present }]" @click="togglePresent()">{{ present ? 'Thoát trình chiếu' : 'Trình chiếu' }}</button>
        <span class="uc-kpi-rf__pill2 is-warn" title="Số liệu lấy từ file các đơn vị đã nộp, chưa qua đối soát">Số liệu thật · chưa xác minh</span>
        <button v-if="page === 0" type="button" class="uc-kpi-rf__simbtn" @click="openImpact(boardWorst, 'siso')">Vùng tác động (ước tính)</button>
        <button v-if="page === 0" type="button" class="uc-kpi-rf__simbtn is-solid" @click="exportPack()">Xuất tài liệu họp (PDF)</button>
        <span v-if="page !== 0" class="uc-kpi-rf__pill2" title="Quy đổi VNĐ theo học phí niêm yết 2026 của LHBS từng cấp (chưa gồm bán trú, chưa trừ ưu đãi)">VNĐ: ước tính</span>
      </div>
    </div>

    <!-- Slicer -->
    <div v-if="!present && [0, 3, 8, 9, 10, 11].indexOf(page) < 0" class="uc-kpi-rf__slicers">
      <div>
        <div class="uc-kpi-rf__slicer-label">Đơn vị</div>
        <div class="uc-kpi-rf__seg">
          <button v-for="o in unitOptions" :key="o.k" type="button" :class="{ 'is-on': unit === o.k }" @click="unit = o.k">{{ o.t }}</button>
        </div>
      </div>
      <div>
        <div class="uc-kpi-rf__slicer-label">Góc nhìn</div>
        <div class="uc-kpi-rf__view">{{ page === 0 ? 'Hội đồng trường' : (unit === 'ALL' ? 'Ban điều hành · hợp nhất' : 'Hiệu trưởng ' + unitLabel(unit)) }}</div>
      </div>
      <div class="uc-kpi-rf__actions">
        <button type="button" class="uc-kpi-rf__simbtn" @click="openImpact(unit)">Vùng tác động (ước tính)</button>
        <button type="button" class="uc-kpi-rf__simbtn is-solid" @click="exportPack()" title="Mở hộp thoại in, chọn &quot;Lưu thành PDF&quot;">Xuất bộ tài liệu họp (PDF)</button>
      </div>
    </div>

    <!-- ================= PAGE 0: HỘI ĐỒNG TRƯỜNG ================= -->
    <div v-if="isAnalysisPage" class="uc-kpi-rf__anbar">
      <b>Màn phân tích</b> Có số giả định và ước tính để thử kịch bản. Không dùng làm số báo cáo chính thức; số báo cáo nằm ở tầng A và D.
    </div>

    <div v-if="page === 0" class="uc-kpi-rf__page uc-kpi-rf__board">
      <!-- 1. Kết luận một câu -->
      <div class="uc-kpi-rf__bhead">
        <div class="uc-kpi-rf__bhead-k">Tóm tắt cho Hội đồng trường · tháng 9/2026</div>
        <div class="uc-kpi-rf__bhead-t">{{ boardHeadline }}</div>
        <div class="uc-kpi-rf__bhead-s">Số theo dõi tháng do đơn vị nộp, chưa qua đối soát; chưa phải kỳ chốt KPI chính thức (kỳ chốt kế tiếp {{ cutUpcoming.length ? cutUpcoming[0].d : '—' }}).</div>
      </div>

      <!-- 2. Bốn chỉ số sống còn -->
      <div class="uc-kpi-rf__bkpis">
        <div v-for="t in boardTiles" :key="t.k" :class="['uc-kpi-rf__bkpi', 'is-' + t.st, { 'is-click': t.go }]" @click="t.go && t.go()">
          <div class="uc-kpi-rf__bkpi-h"><span>{{ t.k }}</span><b v-if="t.st !== 'none'">{{ boardStText[t.st] }}</b></div>
          <div class="uc-kpi-rf__bkpi-m">
            <div class="uc-kpi-rf__bkpi-v">{{ t.v }}</div>
            <svg v-if="t.sp" class="uc-kpi-rf__spark" viewBox="0 0 120 46">
              <line v-if="t.sp.ty !== null" x1="4" x2="116" :y1="t.sp.ty" :y2="t.sp.ty" class="sp-tg"></line>
              <polyline :points="t.sp.line" class="sp-l"></polyline>
              <circle v-for="(q, i) in t.sp.dots" :key="'d' + i" :cx="q.x" :cy="q.y" r="2.8" :class="i === t.sp.dots.length - 1 ? 'sp-d is-last' : 'sp-d'"><title>{{ q.l }}: {{ q.t }}</title></circle>
              <text v-for="(q, i) in t.sp.dots" :key="'x' + i" :x="q.x" y="45" text-anchor="middle" class="sp-x">{{ q.l }}</text>
            </svg>
          </div>
          <div class="uc-kpi-rf__bkpi-d">{{ t.d }}</div>
          <div class="uc-kpi-rf__cmp">
            <span v-for="c in t.cmp" :key="c.k" :class="c.cls"><i>{{ c.k }}</i><b>{{ c.v }}</b></span>
          </div>
          <div class="uc-kpi-rf__bkpi-i">Xem vùng tác động (ước tính) ›</div>
        </div>
      </div>
      <div class="uc-kpi-rf__src uc-kpi-rf__cmpnote">Đường nhỏ: diễn biến theo tháng (T5 = cuối năm học trước), vạch đứt = kế hoạch hoặc ngưỡng. Ô so sánh: kế hoạch, chênh lệch so với kế hoạch, năm học trước. "NH trước" là số cuối năm hoặc cả năm học 2025–2026, chưa phải cùng kỳ tháng 9; chưa có dữ liệu cùng kỳ.</div>

      <!-- 3. Lưu ý và quyết định -->
      <div class="uc-kpi-rf__bcols">
        <div class="uc-kpi-rf__bbox">
          <div class="uc-kpi-rf__bbox-h">Ba điểm Hội đồng cần lưu ý</div>
          <div v-for="(r, i) in boardRisks" :key="i" class="uc-kpi-rf__bitem">
            <span class="uc-kpi-rf__bitem-n">{{ i + 1 }}</span>
            <div><div class="uc-kpi-rf__bitem-t">{{ r.title }}</div><div class="uc-kpi-rf__bitem-d">{{ r.detail }}</div><div class="uc-kpi-rf__bitem-o">Phụ trách: {{ r.owner }}<button v-if="r.imp" type="button" class="uc-kpi-rf__bimp" @click="openImpact(r.imp.u, r.imp.t)">Vùng tác động (ước tính) ›</button></div></div>
          </div>
        </div>
        <div class="uc-kpi-rf__bbox is-dec">
          <div class="uc-kpi-rf__bbox-h">Đề xuất xin quyết định <span>{{ decisions.length }}</span></div>
          <div v-for="(d, i) in decisions" :key="i" class="uc-kpi-rf__bitem">
            <span class="uc-kpi-rf__bitem-n">{{ i + 1 }}</span>
            <div><div class="uc-kpi-rf__bitem-t">{{ d.t }}</div><div class="uc-kpi-rf__bitem-d">{{ d.e }}</div></div>
          </div>
        </div>
      </div>

      <!-- 4. Dải sức khỏe hệ thống đo lường -->
      <div class="uc-kpi-rf__bstrip">
        <button type="button" @click="page = 3">
          <span class="bs-k">KPI chiến lược đo được</span>
          <span class="bs-v">{{ strategicKpis.length - kpiCount['Chưa đủ dữ liệu'] }}<small>/{{ strategicKpis.length }}</small></span>
          <span class="uc-kpi-rf__stack bs-bar"><span v-for="s in kpiStatusOrder" :key="s" :class="'sb-' + statusKey(s)" :style="{ width: (kpiCount[s] / strategicKpis.length * 100) + '%' }"></span></span>
        </button>
        <button type="button" @click="page = 4">
          <span class="bs-k">Điểm lệch số liệu T9</span>
          <span class="bs-v">{{ newIssues.length }}</span>
          <span class="bs-n">+{{ oldIssues.length }} điểm từ bản tổng kết chờ xác nhận</span>
        </button>
        <button type="button" @click="board.more = !board.more">
          <span class="bs-k">Đơn vị cần giải trình</span>
          <span class="bs-v">{{ boardExplain.length }}<small>/{{ unitRows.length }}</small></span>
          <span class="bs-n">{{ boardExplain.join(', ') || 'Không có' }}</span>
        </button>
      </div>

      <!-- 5. Chi tiết cho Ban điều hành (gập) -->
      <button type="button" class="uc-kpi-rf__bmore" @click="board.more = !board.more">{{ board.more ? 'Ẩn chi tiết cho Ban điều hành' : 'Xem chi tiết cho Ban điều hành: giải trình theo đơn vị, kỳ chốt KPI, độ tin cậy số liệu' }}</button>
      <template v-if="board.more">
      <div class="uc-kpi-rf__visual uc-kpi-rf__cutbox">
        <div class="uc-kpi-rf__vhead">
          <div class="uc-kpi-rf__vtitle">Số theo dõi tháng và kỳ chốt KPI <span class="uc-kpi-rf__en">Monitoring vs reporting</span></div>
          <div class="uc-kpi-rf__vnote">Các ô trên là số theo dõi tháng (Tầng A). KPI chính thức (Tầng D) tính theo định nghĩa và kỳ chốt của MASTER KPI.</div>
        </div>
        <div class="uc-kpi-rf__tablewrap">
          <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__table--wrap">
            <thead><tr><th class="ta-l">KPI</th><th class="ta-l">Số theo dõi tháng 9</th><th class="ta-l">KPI tính theo MASTER</th><th class="ta-l">Kỳ chốt kế tiếp</th><th class="ta-l">Còn thiếu để tính đúng</th></tr></thead>
            <tbody>
              <tr v-for="r in cutRows" :key="r.c" class="is-click" @click="openRf(r.c)">
                <td class="ta-l"><b>{{ r.c }}</b><small>{{ r.n }}</small></td>
                <td class="ta-l"><b>{{ r.v }}</b><small>{{ r.vn }}</small></td>
                <td class="ta-l">{{ r.def }}</td>
                <td class="ta-l"><b>{{ r.next.d }}</b><small v-if="r.next.days !== null">còn {{ r.next.days }} ngày</small></td>
                <td class="ta-l tx-muted">{{ r.need }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="uc-kpi-rf__cutnext">
          <b>Các kỳ chốt sắp tới</b>
          <span v-for="e in cutUpcoming" :key="e.d" class="uc-kpi-rf__cutd"><em>{{ e.d }} · còn {{ e.days }} ngày</em><button v-for="c in e.codes" :key="c" type="button" @click="openRf(c)">{{ c }}</button></span>
        </div>
      </div>
      <div class="uc-kpi-rf__grid">
        <!-- Accountability -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Trách nhiệm giải trình theo đơn vị</div>
            <div class="uc-kpi-rf__vnote">Ô đỏ = phải giải trình tại kỳ họp · bấm dòng để xem chi tiết</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table">
              <thead>
                <tr>
                  <th class="ta-l">Đơn vị</th>
                  <th>Sĩ số / chỉ tiêu</th>
                  <th>Rút lũy kế</th>
                  <th>Chuyển đổi</th>
                  <th>CLB / chỉ tiêu</th>
                  <th>Vào / ra T9</th>
                  <th>Thiếu (DT)</th>
                  <th class="ta-l">Báo cáo tháng</th>
                  <th class="ta-l">Giải trình</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in unitRows" :key="r.k" @click="openUnit(r.k)">
                  <td class="ta-l"><b>{{ r.ten }}</b><small>{{ r.owner }}</small></td>
                  <td class="is-click" :class="'cell-' + statusPct(r.pct)" @click.stop="openImpact(r.k, 'siso')" title="Bấm để xem vùng tác động">{{ fmtPct(r.pct, 1) }}<small>{{ fmtInt(r.t9) }}/{{ fmtInt(r.kh) }} · tác động ›</small></td>
                  <td class="is-click" :class="'cell-' + statusRut(r)" @click.stop="openImpact(r.k)" title="Bấm để xem vùng tác động">{{ fmtPct(r.rut, 1) }}<small>{{ r.di }} HS · tác động ›</small></td>
                  <td class="is-click" :class="'cell-' + statusConv(r.fn.conv)" @click.stop="openImpact(r.k, 'conv')" title="Bấm để xem vùng tác động">{{ fmtPct(r.fn.conv, 1) }}<small>{{ r.fn.label }} · tác động ›</small></td>
                  <td :class="'cell-' + statusPct(r.clbPct)">{{ fmtPct(r.clbPct, 0) }}<small>{{ r.clbLabel }}</small></td>
                  <td :class="'cell-' + flowTag[flowT9[r.k].v]">+{{ flowT9[r.k].vin }} / −{{ flowT9[r.k].vout }}<small>{{ flowText[flowT9[r.k].v] }}</small></td>
                  <td>{{ fmtTy(r.vGap) }}</td>
                  <td class="ta-l"><span class="uc-kpi-rf__fmt" :class="'fmt-' + r.fmt.k">{{ r.fmt.t }}</span></td>
                  <td class="ta-l"><span v-if="r.mustExplain" class="uc-kpi-rf__tag is-bad">Cần giải trình</span><span v-else class="uc-kpi-rf__tag is-good">Theo dõi</span></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Chuyển đổi Liên cấp chưa tách được theo cấp (dữ liệu TVTS gộp PTLC). CLB Trung học gộp THCS + THPT. Rút lũy kế tính trên sĩ số T8.</div>
        </div>
        <!-- Data trust -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Số liệu có đáng tin không?</div>
            <div class="uc-kpi-rf__vnote"><a class="uc-kpi-rf__link" @click="page = 4">Chi tiết</a></div>
          </div>
          <div class="uc-kpi-rf__trust">
            <div><b class="tx-bad">{{ newIssues.length }}</b><span>điểm lệch mới phát hiện trong số liệu tháng 9</span></div>
            <div><b class="tx-warn">{{ oldIssues.length }}</b><span>điểm lệch từ bản tổng kết, chờ đơn vị xác nhận</span></div>
            <div><b>4</b><span>định dạng báo cáo khác nhau mỗi tháng (Excel, PPTX, PDF, Word)</span></div>
            <div><b class="tx-good">5/8</b><span>sheet trong Excel vận hành là dữ liệu xuất từ phần mềm, nối tự động được ngay</span></div>
          </div>
          <div class="uc-kpi-rf__callout">Ví dụ: sĩ số T8 {{ fmtInt(all.t8) }} + {{ all.den9 }} đến − {{ all.di9 }} đi = {{ fmtInt(all.t8 + all.den9 - all.di9) }}, nhưng báo cáo T9 ghi {{ fmtInt(all.t9) }} (lệch {{ all.t8 + all.den9 - all.di9 - all.t9 }} HS).</div>
        </div>
      </div>
      </template>
    </div>

    <!-- ================= PAGE 5: MÔ PHỎNG KỊCH BẢN ================= -->
    <div v-if="page === 5" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__simbar">
        <div>
          <div class="uc-kpi-rf__slicer-label">Kịch bản</div>
          <div class="uc-kpi-rf__seg">
            <button v-for="p in simPresets" :key="p.k" type="button" :class="{ 'is-on': simPreset === p.k }" @click="applyPreset(p.k)">{{ p.t }}</button>
          </div>
        </div>
        <div>
          <div class="uc-kpi-rf__slicer-label">Bắt đầu áp dụng</div>
          <select v-model.number="sim.start" class="uc-kpi-rf__select" @change="simPreset = 'custom'">
            <option v-for="o in monthOptions" :key="o.m" :value="o.m">{{ o.t }} · còn {{ Math.round(o.r * 9) }} tháng</option>
          </select>
        </div>
        <div>
          <div class="uc-kpi-rf__slicer-label">Dự báo nền</div>
          <div class="uc-kpi-rf__seg uc-kpi-rf__seg--sm">
            <button type="button" :class="{ 'is-on': sim.mode === 'cons' }" @click="sim.mode = 'cons'" title="Rút học tiếp tục theo nhịp T9, không tự có thêm học sinh">Thận trọng</button>
            <button type="button" :class="{ 'is-on': sim.mode === 'run' }" @click="sim.mode = 'run'" title="Cả nhập học và rút học tiếp tục như tháng 9">Theo nhịp T9</button>
            <button type="button" :class="{ 'is-on': sim.mode === 'hold' }" @click="sim.mode = 'hold'" title="Không đổi so với sĩ số T9">Giữ nguyên T9</button>
          </div>
        </div>
        <div class="uc-kpi-rf__simbar-r">
          <button type="button" class="uc-kpi-rf__simbtn" @click="saveScenario()">Lưu kịch bản để so sánh</button>
        </div>
      </div>

      <!-- Bottom line -->
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Kết luận kịch bản · Bottom line</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t"><span v-for="(p, i) in simSummary" :key="'ss' + i" :class="{ 'tx-strong': p.b }">{{ p.t }}</span></div>
      </div>

      <!-- Governance value cards -->
      <div class="uc-kpi-rf__gv">
        <div class="uc-kpi-rf__gv-group">
          <div class="uc-kpi-rf__gv-h">Giá trị tài chính <i>Financial value</i></div>
          <div class="uc-kpi-rf__gv-row">
            <div class="uc-kpi-rf__gv-c"><span>LN góp năm nay</span><b :class="tone(simCur.dLn)">{{ signTy(simCur.dLn) }}</b><small>Doanh thu {{ signTy(simCur.dRev) }}</small></div>
            <div class="uc-kpi-rf__gv-c"><span>LN các năm sau</span><b :class="tone(simCur.dLtv)">{{ signTy(simCur.dLtv) }}</b><small>Biên 50% · doanh thu {{ signTy(simCur.dLtvRev) }}</small></div>
            <div class="uc-kpi-rf__gv-c"><span>Chi phí thực hiện</span><b>{{ simCur.cost ? '−' + fmtTy(simCur.cost) : '—' }}</b><small>Nhập ở cột chi phí</small></div>
            <div class="uc-kpi-rf__gv-c is-key"><span>Giá trị ròng · ROI (theo LN)</span><b :class="tone(simCur.net)">{{ signTy(simCur.net) }}</b><small>{{ simCur.cost ? 'ROI năm nay ' + fmtNum(simCur.roiYear, 1) + '× · cả vòng đời ' + fmtNum(simCur.roi, 1) + '× · hoàn vốn ' + simCur.payback : 'Chưa nhập chi phí' }}</small></div>
          </div>
        </div>
        <div class="uc-kpi-rf__gv-group">
          <div class="uc-kpi-rf__gv-h">Mục tiêu chiến lược <i>Strategic KPIs · cuối năm học</i></div>
          <div class="uc-kpi-rf__gv-row">
            <div class="uc-kpi-rf__gv-c" :class="'st-l-' + statusPct(simCur.pct)"><span>KPI 1 · Sĩ số / chỉ tiêu</span><b>{{ fmtPct(simBase.pct, 1) }} → {{ fmtPct(simCur.pct, 1) }}</b><small>{{ fmtInt(simBase.end) }} → {{ fmtInt(simCur.end) }} / {{ fmtInt(simCur.kh) }} HS</small></div>
            <div class="uc-kpi-rf__gv-c" :class="'st-l-' + rutStatus(simCur.rutYear)"><span>KPI 3 · Rút học cả năm</span><b>{{ fmtPct(simBase.rutYear, 1) }} → {{ fmtPct(simCur.rutYear, 1) }}</b><small>Đích ≤ 10%</small></div>
            <div class="uc-kpi-rf__gv-c" :class="'st-l-' + statusConv(simCur.conv)"><span>KPI 5 · Chuyển đổi</span><b>{{ fmtPct(simBase.conv, 1) }} → {{ fmtPct(simCur.conv, 1) }}</b><small>Nhịp T9 · đích 30%</small></div>
          </div>
        </div>
        <div class="uc-kpi-rf__gv-group">
          <div class="uc-kpi-rf__gv-h">Trách nhiệm & nguồn lực <i>Accountability & capacity</i></div>
          <div class="uc-kpi-rf__gv-row">
            <div class="uc-kpi-rf__gv-c" :class="simCur.explain > 0 ? 'st-l-bad' : 'st-l-good'"><span>Đơn vị phải giải trình</span><b>{{ simBase.explain }} → {{ simCur.explain }}<small> / 5</small></b><small>{{ explainDiff }}</small></div>
            <div class="uc-kpi-rf__gv-c"><span>Lead cần mỗi tháng</span><b>{{ fmtInt(simBase.leads) }} → {{ fmtInt(simCur.leads) }}</b><small>{{ fmtInt(simCur.leads / activeTvts) }} lead/tư vấn viên/tháng</small></div>
            <div class="uc-kpi-rf__gv-c" :class="simFlags.length ? 'st-l-warn' : 'st-l-good'"><span>Tính khả thi</span><b>{{ simFlags.length ? simFlags.length + ' cảnh báo' : 'Không cảnh báo' }}</b><small>{{ simFlags.length ? simFlags[0] : 'Trong ngưỡng đã quan sát' }}</small></div>
          </div>
        </div>
      </div>

      <div class="uc-kpi-rf__grid">
        <!-- Levers -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Đòn bẩy điều hành <i class="uc-kpi-rf__en">Management levers</i></div>
            <a class="uc-kpi-rf__link" @click="applyPreset('hien')">Đặt lại</a>
          </div>
          <div class="uc-kpi-rf__lv-h">Tuyển sinh <small>(nhịp T9 / tháng)</small></div>
          <table class="uc-kpi-rf__lv">
            <thead><tr><th class="ta-l">Đơn vị</th><th>Lead</th><th>Δ lead</th><th>Chuyển đổi</th><th>Δ điểm</th></tr></thead>
            <tbody>
              <tr v-for="f in simFunnels" :key="'lf' + f.k">
                <td class="ta-l">{{ f.short }}</td>
                <td class="tx-muted">{{ f.l9 }}</td>
                <td><input type="range" min="-50" max="100" step="10" v-model.number="sim.lead[f.k]" @input="simPreset = 'custom'"><em :class="tone(sim.lead[f.k])">{{ sim.lead[f.k] > 0 ? '+' : '' }}{{ sim.lead[f.k] }}%</em></td>
                <td class="tx-muted">{{ fmtPct(f.c9, 1) }}</td>
                <td><input type="range" min="-10" max="20" step="1" v-model.number="sim.conv[f.k]" @input="simPreset = 'custom'"><em :class="tone(sim.conv[f.k])">{{ sim.conv[f.k] > 0 ? '+' : '' }}{{ sim.conv[f.k] }}</em></td>
              </tr>
            </tbody>
          </table>
          <div class="uc-kpi-rf__lv-h">Giữ chân và tuyển bổ sung</div>
          <table class="uc-kpi-rf__lv">
            <thead><tr><th class="ta-l">Đơn vị</th><th>Rút/th</th><th>Giảm rút</th><th>Tuyển bổ sung</th></tr></thead>
            <tbody>
              <tr v-for="u in units" :key="'lu' + u.k">
                <td class="ta-l">{{ unitLabel(u.k) }}</td>
                <td class="tx-muted">{{ u.di9 }}</td>
                <td><input type="range" min="0" max="100" step="10" v-model.number="sim.keep[u.k]" @input="simPreset = 'custom'"><em :class="tone(sim.keep[u.k])">{{ sim.keep[u.k] }}%</em></td>
                <td><input type="range" min="0" max="60" step="1" v-model.number="sim.add[u.k]" @input="simPreset = 'custom'"><em :class="tone(sim.add[u.k])">+{{ sim.add[u.k] }}</em></td>
              </tr>
            </tbody>
          </table>
          <div class="uc-kpi-rf__lv-h">Chi phí thực hiện <small>(triệu VNĐ, ước tính của đơn vị đề xuất)</small></div>
          <div class="uc-kpi-rf__costs">
            <label v-for="c in costItems" :key="c.k"><span>{{ c.t }}</span><input type="number" min="0" step="50" v-model.number="sim.cost[c.k]" @input="simPreset = 'custom'"></label>
          </div>
          <div class="uc-kpi-rf__costhint">Tham chiếu: {{ fmtInt(simCur.newHs) }} HS mới × CAC {{ fmtNum(cacTarget, 1) }} tr ≈ <b>{{ fmtTy(simCur.newHs * cacTarget) }}</b> chi phí tuyển sinh<span v-if="simCur.keptHs > 0.5"> · giữ lại {{ fmtInt(simCur.keptHs) }} HS</span>.</div>
          <div class="uc-kpi-rf__src">Nhịp T9 lấy từ Excel vận hành. Liên cấp: tăng tuyển sinh được chia cho TH/THCS/THPT theo số còn thiếu chỉ tiêu.</div>
        </div>

        <!-- Bridge + criteria -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Đóng góp của từng đòn bẩy <i class="uc-kpi-rf__en">Value bridge</i></div>
            <div class="uc-kpi-rf__vnote">Sĩ số cuối năm học · vạch: chỉ tiêu</div>
          </div>
          <svg class="uc-kpi-rf__svg" viewBox="0 0 640 290" preserveAspectRatio="xMidYMid meet">
            <line v-for="t in simBridge.ticks" :key="'st' + t.v" x1="48" x2="630" :y1="t.y" :y2="t.y" class="g-grid"></line>
            <text v-for="t in simBridge.ticks" :key="'sl' + t.v" x="42" :y="t.y + 4" class="g-axis" text-anchor="end">{{ fmtInt(t.v) }}</text>
            <line v-for="(cn, i) in simBridge.conns" :key="'sc' + i" :x1="cn.x1" :x2="cn.x2" :y1="cn.y" :y2="cn.y" class="g-conn"></line>
            <g v-for="(b, i) in simBridge.bars" :key="'sb' + i">
              <rect :x="b.x" :y="b.y" :width="b.w" :height="b.h" :class="'g-' + b.type"></rect>
              <text :x="b.x + b.w / 2" :y="b.y - 5" text-anchor="middle" class="g-val">{{ b.text }}</text>
              <text v-for="(ln, j) in b.lines" :key="j" :x="b.x + b.w / 2" :y="236 + j * 13" text-anchor="middle" class="g-axis">{{ ln }}</text>
              <text v-if="b.money" :x="b.x + b.w / 2" y="276" text-anchor="middle" class="g-money" :class="b.type === 'up' ? 'is-good' : ''">{{ b.money }}</text>
            </g>
            <line x1="48" x2="630" :y1="simBridge.planY" :y2="simBridge.planY" class="g-plan"></line>
            <text x="630" :y="simBridge.planY - 5" text-anchor="end" class="g-plan-txt">Chỉ tiêu {{ fmtInt(simCur.kh) }}</text>
          </svg>
          <div class="uc-kpi-rf__src">Dòng dưới: LN góp năm nay của từng đòn bẩy (ước tính). Thứ tự đòn bẩy: chuyển đổi → lead → giữ chân → tuyển bổ sung.</div>
        </div>

        <!-- Criteria matrix -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Tác động lên các tiêu chí theo đơn vị <i class="uc-kpi-rf__en">Criteria impact matrix</i></div>
            <div class="uc-kpi-rf__vnote">Số lớn: kịch bản · số nhỏ: dự báo nền · màu theo trạng thái kịch bản</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr>
                <th class="ta-l">Đơn vị</th><th>KPI 1 · sĩ số cuối năm</th><th>KPI 3 · rút cả năm</th><th>KPI 5 · chuyển đổi</th><th>Δ học sinh</th><th>LN góp năm nay</th><th>LN các năm sau</th><th class="ta-l">Giải trình trước HĐ</th>
              </tr></thead>
              <tbody>
                <tr v-for="(r, i) in simCur.units" :key="'sm' + r.k">
                  <td class="ta-l"><b>{{ r.ten }}</b><small>{{ r.owner }}</small></td>
                  <td :class="'cell-' + statusPct(r.pct)">{{ fmtPct(r.pct, 1) }}<small>nền {{ fmtPct(simBase.units[i].pct, 1) }} · {{ fmtInt(r.end) }}/{{ r.kh }}</small></td>
                  <td :class="'cell-' + rutStatus(r.rutYear)">{{ fmtPct(r.rutYear, 1) }}<small>nền {{ fmtPct(simBase.units[i].rutYear, 1) }}</small></td>
                  <td :class="'cell-' + statusConv(r.conv)">{{ fmtPct(r.conv, 1) }}<small>{{ r.don === 'PTLC' ? 'PTLC gộp' : 'nền ' + fmtPct(simBase.units[i].conv, 1) }}</small></td>
                  <td :class="tone(r.dHs)"><b>{{ signed(r.dHs, 0) }}</b></td>
                  <td :class="tone(r.dLn)">{{ signTy(r.dLn) }}</td>
                  <td :class="tone(r.dLtv)">{{ signTy(r.dLtv) }}</td>
                  <td class="ta-l">
                    <span class="uc-kpi-rf__tag" :class="simBase.units[i].explain ? 'is-bad' : 'is-good'">{{ simBase.units[i].explain ? 'Cần' : 'Theo dõi' }}</span> →
                    <span class="uc-kpi-rf__tag" :class="r.explain ? 'is-bad' : 'is-good'">{{ r.explain ? 'Cần giải trình' : 'Theo dõi' }}</span>
                    <small>{{ r.why }}</small>
                  </td>
                </tr>
                <tr class="is-total">
                  <td class="ta-l">Toàn hệ thống</td>
                  <td>{{ fmtPct(simCur.pct, 1) }}<small>nền {{ fmtPct(simBase.pct, 1) }}</small></td>
                  <td>{{ fmtPct(simCur.rutYear, 1) }}<small>nền {{ fmtPct(simBase.rutYear, 1) }}</small></td>
                  <td>{{ fmtPct(simCur.conv, 1) }}<small>nền {{ fmtPct(simBase.conv, 1) }}</small></td>
                  <td :class="tone(simCur.end - simBase.end)">{{ signed(simCur.end - simBase.end, 0) }}</td>
                  <td :class="tone(simCur.dLn)">{{ signTy(simCur.dLn) }}</td>
                  <td :class="tone(simCur.dLtv)">{{ signTy(simCur.dLtv) }}</td>
                  <td class="ta-l">{{ simBase.explain }} → {{ simCur.explain }} đơn vị</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <!-- Goal seek -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Cần gì để đạt đích? <i class="uc-kpi-rf__en">Goal seek</i></div>
          </div>
          <div class="uc-kpi-rf__wi-row">
            <label>Đích sĩ số toàn hệ thống cuối năm <b>{{ fmtPct(sim.target, 0) }}</b></label>
            <input type="range" min="0.85" max="1" step="0.01" v-model.number="sim.target" class="uc-kpi-rf__range">
          </div>
          <div class="uc-kpi-rf__goal">
            <div class="uc-kpi-rf__goal-need"><b>{{ simGoal.need > 0 ? 'Còn thiếu ' + fmtInt(simGoal.need) + ' học sinh' : 'Kịch bản đã đạt đích' }}</b><span v-if="simGoal.need > 0">≈ {{ fmtTy(simGoal.value) }} LN góp năm nay nếu đạt</span></div>
            <div v-for="g in simGoal.options" :key="g.k" class="uc-kpi-rf__goal-row">
              <span>{{ g.k }}</span><b :class="g.ok ? '' : 'tx-bad'">{{ g.v }}</b>
            </div>
          </div>
          <div class="uc-kpi-rf__src">Mỗi dòng là một đòn bẩy dùng riêng lẻ, cộng thêm vào kịch bản hiện tại.</div>
        </div>

        <!-- Compare -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">So sánh kịch bản <i class="uc-kpi-rf__en">Scenario comparison</i></div>
            <a v-if="saved.length" class="uc-kpi-rf__link" @click="clearScenarios()">Xóa</a>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Tiêu chí</th><th>Dự báo nền</th><th v-for="s in saved" :key="'sh' + s.id">{{ s.name }}</th><th>Đang xem</th></tr></thead>
              <tbody>
                <tr v-for="row in compareRows" :key="row.k">
                  <td class="ta-l">{{ row.k }}</td>
                  <td>{{ row.f(simBase) }}</td>
                  <td v-for="s in saved" :key="row.k + s.id">{{ row.f(s.out) }}</td>
                  <td><b>{{ row.f(simCur) }}</b></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Lưu tối đa 3 kịch bản (trên trình duyệt này). Giá trị VNĐ là ước tính theo giả định ở tab Dữ liệu &amp; đối soát.</div>
        </div>

        <!-- Internal feeder scenario (moved from enrollment map) -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Chuyển cấp nội bộ <span class="uc-kpi-rf__en">Internal feeder scenario</span></div>
            <div class="uc-kpi-rf__vnote">Sửa cột "Tỷ lệ lên cấp" để thử giả định · số HS cuối cấp lấy từ tab Bản đồ tuyển sinh</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Mốc chuyển cấp</th><th>HS cuối cấp</th><th>Tỷ lệ lên cấp</th><th>Dự kiến lên cấp</th><th>Doanh thu năm đầu cấp sau</th><th>Mỗi +5 điểm %</th></tr></thead>
              <tbody>
                <tr v-for="f in mapFeeder" :key="f.k">
                  <td class="ta-l"><b>{{ f.t }}</b><small>{{ f.sub }}</small></td>
                  <td>{{ fmtInt(f.base) }}<small class="bm-that">thật · T9</small></td>
                  <td><span class="uc-kpi-rf__pct"><input type="number" min="0" max="100" step="5" v-model.number="feed[f.k]" />%</span><small class="bm-gia">giả định</small></td>
                  <td><b>{{ fmtInt(f.base * f.p) }}</b></td>
                  <td>+{{ fmtTy(f.base * f.p * f.nhp) }}<small>học phí {{ fmtNum(f.nhp, 1) }} triệu/năm</small></td>
                  <td>+{{ fmtNum(f.base * 0.05, 0) }} HS<small>+{{ fmtTy(f.base * 0.05 * f.nhp) }}/năm</small></td>
                </tr>
                <tr class="is-total">
                  <td class="ta-l">Tổng</td><td>{{ fmtInt(feedSum.base) }}</td><td></td><td>{{ fmtInt(feedSum.up) }}</td><td>+{{ fmtTy(feedSum.rev) }}<small class="uc-kpi-rf__est">ước tính</small></td><td>+{{ fmtNum(feedSum.plus5, 0) }} HS</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Tỷ lệ mặc định theo giả định vòng đời (Lá → Lớp 1 40%, Lớp 5 → 6 70%, Lớp 9 → 10 60%). Doanh thu = HS lên cấp × học phí cấp sau (giả định nội bộ, chờ Kế toán). Chưa trừ học sinh lẽ ra vẫn ở lại dù không có chương trình giữ chân.</div>
        </div>

        <!-- Lead pool (moved from enrollment map) -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Lead đang ở đâu, ai đang giữ <span class="uc-kpi-rf__en">Lead pool &amp; ownership</span></div>
            <div class="uc-kpi-rf__vnote">Sửa cột "Thu hồi" để thử giả định · số lead lấy từ tab Bản đồ tuyển sinh</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__pool">
              <thead><tr><th class="ta-l">Nhóm lead</th><th>Lead</th><th class="ta-l">Ai giữ · việc cần làm</th><th>Thu hồi</th><th>HS</th><th>Doanh thu</th></tr></thead>
              <tbody>
                <tr v-for="r in mapPool" :key="r.k" :class="{ 'is-mute': r.fixed }">
                  <td class="ta-l"><b>{{ r.t }}</b><small>{{ r.when }}</small></td>
                  <td><b>{{ fmtInt(r.n) }}</b><small v-if="r.src === 'uoc'" class="uc-kpi-rf__est">ước tính</small></td>
                  <td class="ta-l uc-kpi-rf__pool-act" :title="r.act"><b>{{ r.who }}</b><small>{{ r.act }}</small></td>
                  <td><span v-if="r.fixed" class="tx-muted">—</span><span v-else class="uc-kpi-rf__pct"><input type="number" min="0" max="100" step="5" v-model.number="map.rec[r.k]" />%</span></td>
                  <td><b>{{ fmtNum(r.hs, 0) }}</b></td>
                  <td>{{ r.next ? 'năm sau' : (r.hs ? '+' + fmtTy(r.rev) : '—') }}</td>
                </tr>
                <tr class="is-total">
                  <td class="ta-l">Thu hồi năm nay<small>{{ fmtPct(mapPoolSum.hs / Math.max(mapGap, 1), 0) }} khoảng thiếu đích 30% ({{ fmtInt(mapGap) }} HS)</small></td>
                  <td>{{ fmtInt(mapPoolSum.n) }}</td><td></td><td></td>
                  <td>{{ fmtNum(mapPoolSum.hs, 0) }}</td><td>+{{ fmtTy(mapPoolSum.rev) }}<small class="uc-kpi-rf__est">ước tính</small></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Thu hồi là giả định để thử. Doanh thu = HS × học phí BQ {{ fmtNum(mapHp, 1) }} triệu/năm × {{ fmtPct(remain, 0) }} năm còn lại. Số lead và lý do là dữ liệu thật, trừ dòng có ghi "ước tính".</div>
        </div>

      </div>
    </div>

    <!-- ================= PAGE 1: QUY MÔ & GIỮ CHÂN ================= -->
    <div v-if="page === 1" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Quy mô & giữ chân · {{ unitLabel(unit) }} · tháng 9/2026</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">{{ qmHeadline }}</div>
      </div>
      <div class="uc-kpi-rf__bkpis">
        <div v-for="t in qmTiles" :key="t.k" :class="['uc-kpi-rf__bkpi', 'is-' + t.st, { 'is-click': t.go }]" @click="t.go && t.go()">
          <div class="uc-kpi-rf__bkpi-h"><span>{{ t.k }}</span><b v-if="t.st !== 'none'">{{ boardStText[t.st] }}</b></div>
          <div class="uc-kpi-rf__bkpi-m">
            <div class="uc-kpi-rf__bkpi-v">{{ t.v }}</div>
            <svg v-if="t.sp" class="uc-kpi-rf__spark" viewBox="0 0 120 46">
              <line v-if="t.sp.ty !== null" x1="4" x2="116" :y1="t.sp.ty" :y2="t.sp.ty" class="sp-tg"></line>
              <polyline :points="t.sp.line" class="sp-l"></polyline>
              <circle v-for="(q, i) in t.sp.dots" :key="'d' + i" :cx="q.x" :cy="q.y" r="2.8" :class="i === t.sp.dots.length - 1 ? 'sp-d is-last' : 'sp-d'"><title>{{ q.l }}: {{ q.t }}</title></circle>
              <text v-for="(q, i) in t.sp.dots" :key="'x' + i" :x="q.x" y="45" text-anchor="middle" class="sp-x">{{ q.l }}</text>
            </svg>
          </div>
          <div class="uc-kpi-rf__bkpi-d">{{ t.d }}</div>
          <div class="uc-kpi-rf__cmp">
            <span v-for="c in t.cmp" :key="c.k" :class="c.cls"><i>{{ c.k }}</i><b>{{ c.v }}</b></span>
          </div>
        </div>
      </div>
      <div class="uc-kpi-rf__src uc-kpi-rf__cmpnote">Đường nhỏ: diễn biến theo tháng (T5 = cuối năm học trước), vạch đứt = kế hoạch hoặc ngưỡng. Cột "NH trước" là số cuối năm hoặc cả năm học 2025–2026, chưa phải cùng kỳ tháng 9; chưa có dữ liệu cùng kỳ.</div>
      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">{{ unit === 'ALL' ? 'Theo đơn vị' : 'Theo khối · ' + unitLabel(unit) }}</div>
            <div class="uc-kpi-rf__vnote">Thanh: sĩ số T9 · vạch: chỉ tiêu · bấm dòng đơn vị để đi sâu</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table">
              <thead>
                <tr>
                  <th class="ta-l">{{ unit === 'ALL' ? 'Đơn vị' : 'Khối' }}</th>
                  <th class="ta-l uc-kpi-rf__th-bar">Sĩ số so với chỉ tiêu</th>
                  <th>Chỉ tiêu</th>
                  <th>Cuối NH trước</th>
                  <th>T8</th>
                  <th>T9</th>
                  <th>% đạt</th>
                  <th>Thiếu</th>
                  <th>Lớp</th>
                  <th>HS/lớp</th>
                  <th>Rút</th>
                  <th>Đến</th>
                  <th>DT còn thiếu</th>
                </tr>
              </thead>
              <tbody>
                <tr v-for="r in detailRows" :key="r.k" :class="{ 'is-total': r.total }" @click="drill(r)">
                  <td class="ta-l">{{ r.ten }}</td>
                  <td class="ta-l">
                    <div class="uc-kpi-rf__bullet-track">
                      <span class="is-fill" :class="'st-' + statusPct(r.pct)" :style="{ width: Math.min(100, r.t9 / r.scale * 100) + '%' }"></span>
                      <i :style="{ left: Math.min(100, r.kh / r.scale * 100) + '%' }"></i>
                    </div>
                  </td>
                  <td>{{ fmtInt(r.kh) }}</td>
                  <td class="tx-muted">{{ r.t5 === null ? '—' : fmtInt(r.t5) }}</td>
                  <td>{{ fmtInt(r.t8) }}</td>
                  <td><b>{{ fmtInt(r.t9) }}</b></td>
                  <td :class="'cell-' + statusPct(r.pct)">{{ fmtPct(r.pct, 1) }}</td>
                  <td>{{ r.kh - r.t9 >= 0 ? fmtInt(r.kh - r.t9) : '+' + fmtInt(r.t9 - r.kh) }}</td>
                  <td>{{ r.lop }}</td>
                  <td>{{ fmtNum(r.t9 / r.lop, 1) }}</td>
                  <td>{{ r.di }}</td>
                  <td>{{ r.den }}</td>
                  <td>{{ fmtTy(r.vGap) }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Cuối NH trước = tháng 5/2026 theo bản tổng kết (chỉ có cấp đơn vị). Số lớp theo cột "Số lớp thực tế" trong sheet 1. Cột "Đến" theo khối Liên cấp không khớp tổng cấp (xem tab Dữ liệu & đối soát).</div>
        </div>
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Cầu đối soát: chỉ tiêu → thực tế T9</div>
            <div class="uc-kpi-rf__vnote">Học sinh · dòng dưới: doanh thu còn lại (ước tính)</div>
          </div>
          <svg class="uc-kpi-rf__svg" viewBox="0 0 640 290" preserveAspectRatio="xMidYMid meet">
            <line v-for="t in wf.ticks" :key="'t' + t.v" x1="48" x2="630" :y1="t.y" :y2="t.y" class="g-grid"></line>
            <text v-for="t in wf.ticks" :key="'l' + t.v" x="42" :y="t.y + 4" class="g-axis" text-anchor="end">{{ fmtInt(t.v) }}</text>
            <line v-for="(cn, i) in wf.conns" :key="'c' + i" :x1="cn.x1" :x2="cn.x2" :y1="cn.y" :y2="cn.y" class="g-conn"></line>
            <g v-for="(b, i) in wf.bars" :key="'b' + i">
              <rect :x="b.x" :y="b.y" :width="b.w" :height="b.h" :class="'g-' + b.type"></rect>
              <text :x="b.x + b.w / 2" :y="b.y - 5" text-anchor="middle" class="g-val">{{ b.text }}</text>
              <text v-for="(ln, j) in b.lines" :key="j" :x="b.x + b.w / 2" :y="236 + j * 13" text-anchor="middle" class="g-axis">{{ ln }}</text>
              <text v-if="b.money" :x="b.x + b.w / 2" y="276" text-anchor="middle" class="g-money">{{ b.money }}</text>
            </g>
          </svg>
          <div class="uc-kpi-rf__src">Nguồn: sheet "1. Sĩ số học sinh" · Học phí niêm yết 2026 (chưa gồm bán trú): MN 37,2 · TH 49,6 · THCS 61,7 · THPT 63,6 tr/năm, khớp báo cáo thường niên</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Lý do rút hồ sơ (lũy kế)</div>
            <div class="uc-kpi-rf__vnote">Toàn hệ thống · {{ reasonTotal }} HS</div>
          </div>
          <div class="uc-kpi-rf__hbars">
            <div v-for="r in reasons" :key="r.k" class="uc-kpi-rf__hbar">
              <div class="uc-kpi-rf__hbar-l">{{ r.k }}</div>
              <div class="uc-kpi-rf__hbar-t"><span :style="{ width: (r.v / reasons[0].v * 100) + '%' }"></span></div>
              <div class="uc-kpi-rf__hbar-n">{{ r.v }}</div>
            </div>
          </div>
          <div class="uc-kpi-rf__callout">
            <b>{{ fmtPct(reasons[0].v / reasonTotal, 0) }}</b> rút vì nơi ở/đưa đón — đòn bẩy nằm ở tuyến xe và dịch vụ, không phải chất lượng dạy.
            <b>41/{{ reasonTotal }}</b> rút ngay tháng 8, trước khai giảng.
          </div>
          <div class="uc-kpi-rf__src">"Khác" (14 HS) chưa phân loại — cần danh mục lý do chuẩn.</div>
        </div>

      </div>
      <button type="button" class="uc-kpi-rf__bmore" @click="fold.qm = !fold.qm">{{ fold.qm ? 'Ẩn phân tích dòng vào – ra' : 'Xem phân tích dòng vào – ra theo đơn vị và thử nhanh kịch bản' }}</button>
      <div v-if="fold.qm" class="uc-kpi-rf__grid">
        <!-- Student flow -->
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Dòng học sinh vào – ra: giữ chân, rút, bù đắp <i class="uc-kpi-rf__en">Student flow & retention</i></div>
            <div class="uc-kpi-rf__seg uc-kpi-rf__seg--sm">
              <button v-for="o in flowPeriods" :key="o.k" type="button" :class="{ 'is-on': flowPeriod === o.k }" @click="flowPeriod = o.k">{{ o.t }}</button>
            </div>
          </div>
          <div class="uc-kpi-rf__flow">
            <!-- Quadrant -->
            <div class="uc-kpi-rf__flow-q">
              <svg viewBox="0 0 420 330" class="uc-kpi-rf__svg">
                <rect x="50" y="10" :width="FQ.xMid - 50" :height="FQ.yMid - 10" class="q-good"></rect>
                <rect :x="FQ.xMid" y="10" :width="410 - FQ.xMid" :height="FQ.yMid - 10" class="q-warn"></rect>
                <rect x="50" :y="FQ.yMid" :width="FQ.xMid - 50" :height="290 - FQ.yMid" class="q-warn"></rect>
                <rect :x="FQ.xMid" :y="FQ.yMid" :width="410 - FQ.xMid" :height="290 - FQ.yMid" class="q-bad"></rect>
                <text x="56" :y="FQ.yMid - 7" class="q-lbl">Khỏe mạnh</text>
                <text x="404" :y="FQ.yMid - 7" class="q-lbl" text-anchor="end">Rò rỉ, đang bù bằng tuyển mới</text>
                <text x="58" y="282" class="q-lbl">Thiếu nguồn vào</text>
                <text x="402" y="282" class="q-lbl q-lbl-bad" text-anchor="end">Báo động</text>
                <line :x1="FQ.xMid" :x2="FQ.xMid" y1="10" y2="290" class="q-axis2"></line>
                <line x1="50" x2="410" :y1="FQ.yMid" :y2="FQ.yMid" class="q-axis2"></line>
                <text v-for="t in FQ.xticks" :key="'xt' + t.t" :x="t.x" y="303" class="g-axis" text-anchor="middle">{{ fmtNum(t.t, t.t < 1 ? 1 : 0) }}×</text>
                <text :x="FQ.xMid + 4" y="20" class="g-axis">← nhịp cho phép</text>
                <text x="46" :y="FQ.yMid + 3" class="g-axis" text-anchor="end">bù đủ 1,0</text>
                <text x="230" y="322" class="g-axis" text-anchor="middle">Tỷ lệ rút so với nhịp KPI 3 (thang căn bậc hai) →</text>
                <text x="14" y="150" class="g-axis" text-anchor="middle" transform="rotate(-90 14 150)">Tỷ lệ bù đắp vào/ra →</text>
                <g v-for="d in FQ.dots" :key="'fq' + d.k">
                  <circle :cx="d.x" :cy="d.y" :r="d.r" :class="'q-dot q-' + d.v"></circle>
                  <text :x="d.lx" :y="d.lyy" :text-anchor="d.la" class="q-name">{{ d.label }}</text>
                </g>
              </svg>
              <div class="uc-kpi-rf__src">Kích thước chấm = sĩ số. Trục ngang: tỷ lệ rút trong kỳ chia cho nhịp cho phép (10%/năm ≈ 1%/tháng). Trục dọc: số vào chia số ra (giới hạn hiển thị 3,0).</div>
            </div>
            <!-- Table -->
            <div class="uc-kpi-rf__flow-t">
              <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
                <thead><tr><th class="ta-l">Đơn vị</th><th>Đầu kỳ</th><th>Vào</th><th>Ra</th><th>Ròng</th><th>Rút kỳ</th><th>Giữ chân</th><th>Bù đắp</th><th>Quy năm</th><th class="ta-l">Phán định</th></tr></thead>
                <tbody>
                  <tr v-for="r in flowRows" :key="'fr' + r.k" :class="{ 'is-total': r.total }">
                    <td class="ta-l">{{ r.ten }}</td>
                    <td>{{ fmtInt(r.base) }}</td>
                    <td class="tx-good">+{{ r.vin }}</td>
                    <td class="tx-bad">−{{ r.vout }}</td>
                    <td :class="r.net >= 0 ? 'tx-good' : 'tx-bad'"><b>{{ signed(r.net, 0) }}</b></td>
                    <td :class="'cell-' + (r.rate <= r.pace ? 'good' : 'bad')">{{ fmtPct(r.rate, 1) }}<small>nhịp {{ fmtPct(r.pace, 1) }}</small></td>
                    <td>{{ fmtPct(1 - r.rate, 1) }}</td>
                    <td :class="'cell-' + (r.repl >= 1 ? 'good' : 'bad')">{{ r.vout ? fmtNum(r.repl, 2) : '—' }}</td>
                    <td :class="r.annual > rutTargetYear ? 'tx-bad' : ''">{{ fmtPct(r.annual, 1) }}</td>
                    <td class="ta-l"><span class="uc-kpi-rf__tag" :class="'is-' + flowTag[r.v]">{{ flowText[r.v] }}</span></td>
                  </tr>
                </tbody>
              </table>
              <div class="uc-kpi-rf__src">
                Đầu kỳ T9 = sĩ số T8; đầu kỳ T8 và lũy kế được suy ngược từ sĩ số T8/T9 và số vào–ra (chưa có sĩ số 31/07).
                Quy năm = tỷ lệ rút mỗi tháng × 10 tháng, so với đích KPI 3 ≤ 10%.
              </div>

              <!-- Quick check -->
              <div class="uc-kpi-rf__qc">
                <div class="uc-kpi-rf__qc-h">Thử nhanh: vào bao nhiêu, ra bao nhiêu thì tốt hay xấu? <i class="uc-kpi-rf__en">Quick check</i></div>
                <div class="uc-kpi-rf__qc-in">
                  <label>Đơn vị
                    <select v-model="quick.unit" class="uc-kpi-rf__select">
                      <option v-for="u in units" :key="'qu' + u.k" :value="u.k">{{ unitLabel(u.k) }} ({{ u.t9 }} HS)</option>
                    </select>
                  </label>
                  <label>Vào <input type="number" min="0" v-model.number="quick.vin"></label>
                  <label>Ra <input type="number" min="0" v-model.number="quick.vout"></label>
                  <label>Trong
                    <select v-model.number="quick.months" class="uc-kpi-rf__select">
                      <option :value="1">1 tháng</option><option :value="2">2 tháng</option><option :value="3">3 tháng</option>
                    </select>
                  </label>
                </div>
                <div class="uc-kpi-rf__qc-out" :class="'is-' + flowTag[quickCheck.v]">
                  <div class="uc-kpi-rf__qc-verdict">{{ flowText[quickCheck.v] }}</div>
                  <div class="uc-kpi-rf__qc-why">{{ quickCheck.why }}</div>
                  <div class="uc-kpi-rf__qc-nums">
                    <span>Ròng <b>{{ signed(quickCheck.net, 0) }}</b></span>
                    <span>Rút kỳ <b>{{ fmtPct(quickCheck.rate, 1) }}</b> / nhịp {{ fmtPct(quickCheck.pace, 1) }}</span>
                    <span>Giữ chân <b>{{ fmtPct(1 - quickCheck.rate, 1) }}</b></span>
                    <span>Bù đắp <b>{{ quick.vout ? fmtNum(quickCheck.repl, 2) : '—' }}</b></span>
                    <span>Quy năm <b>{{ fmtPct(quickCheck.annual, 1) }}</b></span>
                    <span>Tiền <b :class="quickCheck.money < 0 ? 'tx-bad' : 'tx-good'">{{ signTy(quickCheck.money) }}</b> <small>doanh thu còn lại năm học (ước tính)</small></span>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

      </div>
    </div>

    <!-- ================= PAGE 2: TUYỂN SINH ================= -->
    <div v-if="page === 2" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Tuyển sinh · tháng 8–9/2026</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">{{ tsHeadline }}</div>
      </div>
      <div class="uc-kpi-rf__bkpis">
        <div v-for="t in tsTiles" :key="t.k" :class="['uc-kpi-rf__bkpi', 'is-' + t.st, { 'is-click': t.go }]" @click="t.go && t.go()">
          <div class="uc-kpi-rf__bkpi-h"><span>{{ t.k }}</span><b v-if="t.st !== 'none'">{{ boardStText[t.st] }}</b></div>
          <div class="uc-kpi-rf__bkpi-m">
            <div class="uc-kpi-rf__bkpi-v">{{ t.v }}</div>
            <svg v-if="t.sp" class="uc-kpi-rf__spark" viewBox="0 0 120 46">
              <line v-if="t.sp.ty !== null" x1="4" x2="116" :y1="t.sp.ty" :y2="t.sp.ty" class="sp-tg"></line>
              <polyline :points="t.sp.line" class="sp-l"></polyline>
              <circle v-for="(q, i) in t.sp.dots" :key="'d' + i" :cx="q.x" :cy="q.y" r="2.8" :class="i === t.sp.dots.length - 1 ? 'sp-d is-last' : 'sp-d'"><title>{{ q.l }}: {{ q.t }}</title></circle>
              <text v-for="(q, i) in t.sp.dots" :key="'x' + i" :x="q.x" y="45" text-anchor="middle" class="sp-x">{{ q.l }}</text>
            </svg>
          </div>
          <div class="uc-kpi-rf__bkpi-d">{{ t.d }}</div>
          <div class="uc-kpi-rf__cmp">
            <span v-for="c in t.cmp" :key="c.k" :class="c.cls"><i>{{ c.k }}</i><b>{{ c.v }}</b></span>
          </div>
        </div>
      </div>
      <div class="uc-kpi-rf__src uc-kpi-rf__cmpnote">Đường nhỏ: diễn biến theo tháng (T5 = cuối năm học trước), vạch đứt = kế hoạch hoặc ngưỡng. Cột "NH trước" là số cuối năm hoặc cả năm học 2025–2026, chưa phải cùng kỳ tháng 9; chưa có dữ liệu cùng kỳ.</div>
      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Lead → nhập học theo đơn vị (T8 + T9)</div>
            <div class="uc-kpi-rf__vnote">Vạch đứt: mức nhập học nếu đạt 30%</div>
          </div>
          <div class="uc-kpi-rf__funits">
            <div v-for="f in funnels" :key="f.k" class="uc-kpi-rf__funit is-click" @click="openImpact(f.k === 'PTLC' ? 'TH' : f.k, 'conv')" title="Bấm để xem vùng tác động">
              <div class="uc-kpi-rf__funit-h"><b>{{ f.ten }} <span class="uc-kpi-rf__hint2">vùng tác động (ước tính) ›</span></b><span :class="f.conv < 0.3 ? 'tx-bad' : 'tx-good'">{{ fmtPct(f.conv, 1) }}</span></div>
              <div class="uc-kpi-rf__funit-row"><span>Lead</span><div><i class="is-lead" :style="{ width: (f.leads / funnelMax * 100) + '%' }"></i></div><b>{{ f.leads }}</b></div>
              <div class="uc-kpi-rf__funit-row"><span>Nhập học</span><div><i class="is-nh" :style="{ width: (f.nh / funnelMax * 100) + '%' }"></i><em :style="{ left: (f.leads * 0.3 / funnelMax * 100) + '%' }"></em></div><b>{{ f.nh }}</b></div>
              <div class="uc-kpi-rf__funit-d">Thiếu {{ fmtInt(f.gapHs) }} HS so với mức 30% ≈ {{ fmtTy(f.gapHs * f.hp) }}/năm · T8 {{ fmtPct(f.c8, 0) }} → T9 {{ fmtPct(f.c9, 0) }}</div>
            </div>
          </div>
          <div class="uc-kpi-rf__callout">
            Toàn hệ thống {{ fmtPct(funnelAll.conv, 1) }} ({{ funnelAll.nh }}/{{ funnelAll.leads }}), năm trước 14%.
            Lưu ý: chuyển đổi đang tính theo tháng nên dao động mạnh (MN Long Khánh 4% ở T8 → 16% ở T9) vì học sinh nhập học tháng này thường đến từ lead tháng trước — cần tính theo cohort lead.
          </div>
          <div class="uc-kpi-rf__src">Nguồn: sheet "8. Tư vấn tuyển sinh" (Excel tracking TVTS, nhập tay). Liên cấp (PTLC) chưa tách theo cấp học.</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Vì sao lead không thành học sinh?</div>
            <div class="uc-kpi-rf__vnote">Mầm non · T8 + T9</div>
          </div>
          <div class="uc-kpi-rf__hbars">
            <div v-for="(r, i) in failReasons" :key="r.k" class="uc-kpi-rf__hbar">
              <div class="uc-kpi-rf__hbar-l">{{ r.k }}</div>
              <div class="uc-kpi-rf__hbar-t"><span :class="{ 'is-bad': i === 0 }" :style="{ width: (r.v / failReasons[0].v * 100) + '%' }"></span></div>
              <div class="uc-kpi-rf__hbar-n">{{ r.v }}</div>
            </div>
          </div>
          <div class="uc-kpi-rf__callout">
            <b>{{ fmtPct(failReasons[0].v / failTotal, 0) }}</b> lead thất bại vì <b>không liên lạc được sau 3 lần gọi</b>.
            Vấn đề nằm ở chất lượng lead và tốc độ phản hồi, không phải học phí (chỉ {{ failHocPhi }} trường hợp).
          </div>
        </div>

      </div>
      <button type="button" class="uc-kpi-rf__bmore" @click="fold.ts = !fold.ts">{{ fold.ts ? 'Ẩn chi tiết' : 'Xem chi tiết: lead theo tư vấn viên, nguồn biết đến trường' }}</button>
      <div v-if="fold.ts" class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Lead theo tư vấn viên</div>
            <button type="button" class="uc-kpi-rf__namebtn" @click="showNames = !showNames">{{ showNames ? 'Ẩn tên' : 'Hiện tên (Ban điều hành)' }}</button>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Tư vấn viên</th><th>T8</th><th>T9</th><th>Tổng</th><th class="ta-l">Tỷ trọng</th></tr></thead>
              <tbody>
                <tr v-for="t in tvts" :key="t.k">
                  <td class="ta-l">{{ showNames ? t.k : 'Tư vấn viên ' + t.code }}</td><td>{{ t.t8 }}</td><td>{{ t.t9 }}</td><td><b>{{ t.t8 + t.t9 }}</b></td>
                  <td class="ta-l"><div class="uc-kpi-rf__dbar"><span :style="{ width: ((t.t8 + t.t9) / tvtsTotal * 100) + '%' }"></span><em>{{ fmtPct((t.t8 + t.t9) / tvtsTotal, 0) }}</em></div></td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src" style="margin-top:4px;padding-top:0">Tên được ẩn mặc định — đánh giá cá nhân thuộc phạm vi Ban điều hành và Trưởng nhóm TVTS, không đưa lên tầng Hội đồng. Chưa có số nhập học theo từng người.</div>
          <div class="uc-kpi-rf__callout">2 tư vấn viên xử lý <b>{{ fmtPct(tvtsTop2, 0) }}</b> lead — rủi ro quá tải và phụ thuộc người. Muốn đánh giá hiệu quả từng người cần gắn mã TVTS vào hồ sơ nhập học (CRM).</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Phụ huynh biết đến trường qua đâu</div>
            <div class="uc-kpi-rf__vnote">T8 + T9</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Nguồn</th><th>Liên cấp</th><th>MN Biên Hòa</th></tr></thead>
              <tbody>
                <tr v-for="s in sources" :key="s.k"><td class="ta-l">{{ s.k }}</td><td>{{ s.ptlc }}</td><td>{{ s.mnbh }}</td></tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Facebook chiếm phần lớn; kênh Đại sứ và Sự kiện gần như bằng 0. MN Long Khánh: Facebook 232 lead.</div>
        </div>
      </div>
    </div>

    <!-- ================= PAGE 3: RESULTS FRAMEWORK ================= -->
    <div v-if="page === 3" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Results Framework · 18 KPI chiến lược theo MASTER KPI</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">{{ rfHeadline }}</div>
      </div>

      <!-- 7 KPI cấp hệ thống -->
      <div class="uc-kpi-rf__visual uc-kpi-rf__rfblock">
        <div class="uc-kpi-rf__vhead">
          <div class="uc-kpi-rf__vtitle">KPI cấp hệ thống <span class="uc-kpi-rf__en">System-level KPIs</span></div>
          <div class="uc-kpi-rf__rflegend">
            <span v-for="s in kpiStatusOrder" :key="s" :class="'ks-' + statusKey(s)"><i></i>{{ s }} {{ kpiCount[s] }}</span>
          </div>
        </div>
        <div class="uc-kpi-rf__sks">
          <button v-for="k in rfSystem" :key="k.c" type="button" :class="['uc-kpi-rf__sk', 'ks-' + statusKey(rfStatus(k.c))]" :title="k.n" @click="openRf(k.c)">
            <span class="sk-h"><b>{{ k.c }}</b><em>{{ rfStatus(k.c) }}</em></span>
            <span class="sk-n">{{ rfShort(k.c) }}</span>
            <span class="sk-b"><span class="uc-kpi-rf__minibar"><i :style="{ width: rfBase(k.c) + '%' }"></i></span><small>baseline {{ rfBase(k.c) }}%</small></span>
            <span class="sk-c">Chốt {{ rfNext(k).d }}</span>
          </button>
        </div>
      </div>

      <!-- Chuỗi kết quả -->
      <div class="uc-kpi-rf__visual uc-kpi-rf__rfblock">
        <div class="uc-kpi-rf__vhead">
          <div class="uc-kpi-rf__vtitle">Chuỗi kết quả <span class="uc-kpi-rf__en">Goal → priority change → KPI</span></div>
          <button type="button" class="uc-kpi-rf__simbtn" @click="rfv.act = !rfv.act">{{ rfv.act ? 'Ẩn hành động' : 'Hiện hành động' }}</button>
        </div>
        <div class="uc-kpi-rf__chain">
          <div v-for="g in rfTree" :key="g.c" class="uc-kpi-rf__cg">
            <div class="uc-kpi-rf__cg-h">
              <span class="cg-n">{{ g.c }}</span>
              <span class="cg-t" :title="g.t">{{ g.t }}</span>
            </div>
            <div class="uc-kpi-rf__cg-m">{{ rfGoalStat(g).has }}/{{ rfGoalStat(g).n }} KPI có kết quả · baseline {{ rfGoalStat(g).base }}%</div>
            <div v-for="o in g.out" :key="o.c" class="uc-kpi-rf__co">
              <div class="uc-kpi-rf__co-h" :title="o.t"><b>{{ o.c }}</b><span>{{ o.t }}</span></div>
              <ul v-if="rfv.act" class="uc-kpi-rf__rfact"><li v-for="x in o.act" :key="x.c"><i>{{ x.c }}</i> {{ x.t }}</li></ul>
              <button v-for="k in rfOfOut(o.c)" :key="k.c" type="button" :class="['uc-kpi-rf__kr', 'ks-' + statusKey(rfStatus(k.c))]" :title="k.n" @click="openRf(k.c)">
                <i></i><b>{{ k.c }}</b><span>{{ rfShort(k.c) }}</span><em>{{ rfStatus(k.c) }}</em>
              </button>
            </div>
          </div>
        </div>
        <div class="uc-kpi-rf__src">Nguồn: MASTER KPI LHBS (sheet "MA TRAN KET QUA", "KPI LIST"). Trạng thái lấy từ báo cáo tổng kết NH 2025–2026; định nghĩa KPI đang ở bản Draft. Bấm một KPI để mở phiếu mô tả.</div>
      </div>

      <!-- Chi tiết -->
      <div class="uc-kpi-rf__visual uc-kpi-rf__rfblock">
        <div class="uc-kpi-rf__vhead">
          <div class="uc-kpi-rf__seg uc-kpi-rf__seg--sm">
            <button type="button" :class="{ 'is-on': rfv.tab === 'base' }" @click="rfv.tab = 'base'">Tiến độ baseline 2020–2025 · {{ rfStats.base }}%</button>
            <button type="button" :class="{ 'is-on': rfv.tab === 'ev' }" @click="rfv.tab = 'ev'">Bằng chứng NH 2025–2026</button>
            <button type="button" :class="{ 'is-on': rfv.tab === 'code' }" @click="rfv.tab = 'code'">Đối chiếu mã KPI</button>
          </div>
          <div v-if="rfv.tab === 'ev'" class="uc-kpi-rf__seg uc-kpi-rf__seg--sm">
            <button type="button" :class="{ 'is-on': kpiFilter === 'all' }" @click="kpiFilter = 'all'">Tất cả</button>
            <button v-for="s in kpiStatusOrder" :key="s" type="button" :class="{ 'is-on': kpiFilter === s }" @click="kpiFilter = s">{{ s }} ({{ kpiCount[s] }})</button>
          </div>
          <div v-if="rfv.tab === 'code'" class="uc-kpi-rf__vnote">Cần anh Thái xác nhận bộ mã dùng chung</div>
        </div>
        <template v-if="rfv.tab === 'base'">
          <div class="uc-kpi-rf__rfbasegrid">
            <div v-for="k in rfDict" :key="k.c" class="uc-kpi-rf__rfbasecard" @click="openRf(k.c)">
              <div class="bh"><b>{{ k.c }}</b><span>{{ rfBase(k.c) }}%</span></div>
              <div v-for="b in (rfBaseline[k.c] || [])" :key="b.u" class="br">
                <span :title="b.u">{{ b.u }}</span>
                <div class="uc-kpi-rf__minibar"><i :style="{ width: b.p + '%' }"></i></div>
                <em v-if="b.nb">không có baseline</em>
              </div>
            </div>
          </div>
          <div class="uc-kpi-rf__src">Mỗi đơn vị có một đầu mối được phân công; dashboard chỉ hiển thị đơn vị và tiến độ, không hiển thị thông tin cá nhân.</div>
        </template>
        <template v-if="rfv.tab === 'ev'">
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__table--wrap">
              <thead>
                <tr><th class="ta-l">Mã</th><th class="ta-l">KPI</th><th class="ta-l">Bằng chứng NH 2025–2026</th><th class="ta-l">Số liệu T9/2026</th><th class="ta-l">Đánh giá</th><th class="ta-l">Đơn vị sở hữu</th><th class="ta-l">Cần bổ sung</th></tr>
              </thead>
              <tbody>
                <tr v-for="k in kpisFiltered" :key="k.code">
                  <td class="ta-l tx-strong">{{ k.code }}</td>
                  <td class="ta-l">{{ k.name }}</td>
                  <td class="ta-l">{{ k.ev }}</td>
                  <td class="ta-l">{{ k.t9 || '—' }}</td>
                  <td class="ta-l"><span class="uc-kpi-rf__tag" :class="'is-' + statusKey(k.status)">{{ k.status }}</span></td>
                  <td class="ta-l">{{ k.owner }}</td>
                  <td class="ta-l tx-muted">{{ k.need }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Nguồn: Báo cáo tổng kết NH 2025–2026, mục 3. Cột "Số liệu T9/2026" lấy từ Dashboard vận hành tháng 9 và báo cáo tháng MNTB.</div>
        </template>
        <template v-if="rfv.tab === 'code'">
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Nội dung</th><th>MASTER KPI (khung RF)</th><th>Bản tổng kết NH 25–26</th><th>Phương án 19/10 (triển khai)</th><th class="ta-l">Trạng thái</th></tr></thead>
              <tbody>
                <tr v-for="c in codeMap" :key="c.n">
                  <td class="ta-l">{{ c.n }}</td><td><b>{{ c.m }}</b></td><td>{{ c.a }}</td><td>{{ c.b }}</td>
                  <td class="ta-l"><span class="uc-kpi-rf__tag" :class="c.m === c.b ? 'is-good' : 'is-warn'">{{ c.m === c.b ? 'Khớp' : 'Khác mã · cần xác nhận' }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </template>
      </div>
    </div>

    <!-- ================= PAGE 4: DỮ LIỆU ================= -->
    <div v-if="page === 4" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Điểm lệch mới phát hiện trong số liệu tháng 9</div>
            <div class="uc-kpi-rf__vnote">Hệ thống tự kiểm tra chéo khi nạp dữ liệu</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__table--wrap">
              <thead><tr><th class="ta-l">#</th><th class="ta-l">Nội dung</th><th class="ta-l">Nguồn 1</th><th class="ta-l">Nguồn 2</th><th class="ta-l">Chênh</th><th class="ta-l">Cần ai xác nhận</th></tr></thead>
              <tbody>
                <tr v-for="(d, i) in newIssues" :key="i">
                  <td class="ta-l">{{ i + 1 }}</td><td class="ta-l tx-strong">{{ d.n }}</td><td class="ta-l">{{ d.a }}</td><td class="ta-l">{{ d.b }}</td>
                  <td class="ta-l"><span class="uc-kpi-rf__tag is-bad">{{ d.d }}</span></td><td class="ta-l">{{ d.o }}</td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Nguồn báo cáo hiện tại và lộ trình tự động hóa</div>
            <div class="uc-kpi-rf__vnote">Từ bộ báo cáo tháng 9</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__table--wrap">
              <thead><tr><th class="ta-l">Nội dung</th><th class="ta-l">Hiện tại</th><th class="ta-l">Hệ thống gốc</th><th class="ta-l">Lộ trình</th></tr></thead>
              <tbody>
                <tr v-for="s in feeds" :key="s.n">
                  <td class="ta-l tx-strong">{{ s.n }}</td><td class="ta-l">{{ s.now }}</td><td class="ta-l">{{ s.sys }}</td>
                  <td class="ta-l"><span class="uc-kpi-rf__tag" :class="'is-' + s.st">{{ s.plan }}</span></td>
                </tr>
              </tbody>
            </table>
          </div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Điểm lệch từ bản tổng kết, chờ xác minh</div>
            <div class="uc-kpi-rf__vnote">{{ oldIssues.length }} mục</div>
          </div>
          <ol class="uc-kpi-rf__olist">
            <li v-for="(d, i) in oldIssues" :key="i"><b>{{ d.n }}</b> — {{ d.d }}</li>
          </ol>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Giả định dùng để quy đổi VNĐ</div>
            <div class="uc-kpi-rf__vnote">Thay bằng số Kế toán khi có P&amp;L</div>
          </div>
          <div class="uc-kpi-rf__assume">
            <div v-for="a in assumptions" :key="a.k"><span>{{ a.k }}</span><b>{{ a.v }}</b></div>
          </div>
        </div>
      </div>
    </div>

    <!-- ================= IMPACT PANEL (spotlight) ================= -->
    <div v-if="impact.open" class="uc-kpi-rf__spot" @click.self="impact.open = false">
      <div class="uc-kpi-rf__sp">
        <!-- Header -->
        <div class="uc-kpi-rf__sp-head">
          <div class="uc-kpi-rf__sp-titles">
            <div class="uc-kpi-rf__sp-kicker">Vùng tác động (ước tính) · công cụ phân tích, không phải số KPI chính thức</div>
            <div class="uc-kpi-rf__sp-title">{{ cur.title }}</div>
          </div>
          <div class="uc-kpi-rf__sp-types">
            <button v-for="t in impactTypes" :key="t.k" type="button" :class="{ 'is-on': impact.type === t.k }" @click="impact.type = t.k; impact.hover = ''">{{ t.t }}</button>
          </div>
          <button type="button" class="uc-kpi-rf__sp-x" @click="impact.open = false" title="Đóng (Esc)">×</button>
        </div>

        <div class="uc-kpi-rf__sp-body">
          <!-- Left rail: assumptions -->
          <aside class="uc-kpi-rf__sp-rail">
            <div class="uc-kpi-rf__sp-rail-h">Giả định</div>
            <template v-if="impact.type !== 'conv'">
              <div class="uc-kpi-rf__sp-f">
                <label>Đơn vị</label>
                <div class="uc-kpi-rf__sp-opts">
                  <button v-for="u in units" :key="u.k" type="button" :class="{ 'is-on': impact.unit === u.k }" @click="impact.unit = u.k">{{ unitLabel(u.k) }}</button>
                </div>
              </div>
              <div class="uc-kpi-rf__sp-f" v-if="impact.type === 'rut'">
                <label>Số học sinh rời đi <b>{{ impact.n }}</b></label>
                <input type="range" min="1" max="30" step="1" v-model.number="impact.n" class="uc-kpi-rf__range">
              </div>
              <div class="uc-kpi-rf__sp-f" v-if="impact.type === 'siso'">
                <label>Tuyển thêm <b>{{ impact.addN }}</b> học sinh</label>
                <input type="range" min="1" max="80" step="1" v-model.number="impact.addN" class="uc-kpi-rf__range">
              </div>
              <div class="uc-kpi-rf__sp-f">
                <label>{{ impact.type === 'rut' ? 'Thời điểm rời' : 'Thời điểm nhập học' }}</label>
                <select v-model.number="impact.month" class="uc-kpi-rf__select">
                  <option v-for="o in monthOptions" :key="o.m" :value="o.m">{{ o.t }}</option>
                </select>
              </div>
              <div class="uc-kpi-rf__sp-f" v-if="impact.type === 'rut'">
                <label>Lý do rời đi</label>
                <div class="uc-kpi-rf__sp-opts is-col">
                  <button v-for="(r, i) in reasonRoutes" :key="r.k" type="button" :class="{ 'is-on': impact.reason === i }" @click="impact.reason = i">{{ r.k }}</button>
                </div>
              </div>
            </template>
            <template v-else>
              <div class="uc-kpi-rf__sp-f">
                <label>Đơn vị tuyển sinh</label>
                <div class="uc-kpi-rf__sp-opts is-col">
                  <button v-for="f in funnels" :key="f.k" type="button" :class="{ 'is-on': impact.convUnit === f.k }" @click="impact.convUnit = f.k">{{ f.ten }}</button>
                </div>
              </div>
              <div class="uc-kpi-rf__sp-f">
                <label>Chuyển đổi thay đổi <b>{{ impact.convDelta > 0 ? '+' : '' }}{{ impact.convDelta }} điểm</b></label>
                <input type="range" min="-10" max="20" step="1" v-model.number="impact.convDelta" class="uc-kpi-rf__range">
              </div>
              <div class="uc-kpi-rf__sp-f">
                <label>Áp dụng trong</label>
                <select v-model.number="impact.convMonths" class="uc-kpi-rf__select">
                  <option v-for="mm in [1, 2, 3, 4, 6, 8]" :key="mm" :value="mm">{{ mm }} tháng tới</option>
                </select>
              </div>
            </template>
            <div class="uc-kpi-rf__sp-rail-note">Số liệu nền: tháng 9/2026. Tiền quy đổi theo học phí niêm yết 2026 từng cấp (chưa gồm bán trú, chưa trừ ưu đãi); xem tab Dữ liệu &amp; đối soát.</div>
          </aside>

          <!-- Main -->
          <main class="uc-kpi-rf__sp-main">
            <!-- Hero -->
            <section class="uc-kpi-rf__sp-hero">
              <div class="uc-kpi-rf__sp-bl"><span class="uc-kpi-rf__sp-bl-k">Kết luận</span><em class="uc-kpi-rf__nar is-inline" :title="narrative.note">{{ narrative.t }}</em><span v-for="(p, i) in cur.sum" :key="'h' + i" :class="{ 'tx-strong': p.b }">{{ p.t }}</span></div>
              <div class="uc-kpi-rf__sp-kpis">
                <div v-for="h in cur.hero" :key="h.k" class="uc-kpi-rf__sp-kpi" :class="'is-' + h.tone">
                  <div class="uc-kpi-rf__sp-kpi-k">{{ h.k }}</div>
                  <div class="uc-kpi-rf__sp-kpi-v"><small v-if="h.from" class="uc-kpi-rf__sp-kpi-from">{{ h.from }} →</small>{{ h.v }}</div>
                  <div class="uc-kpi-rf__sp-kpi-s">{{ h.sub }}</div>
                  <span class="uc-kpi-rf__src-tag" :class="'src-' + h.src">{{ srcText[h.src] }}</span>
                </div>
              </div>
            </section>

            <!-- Tree -->
            <section class="uc-kpi-rf__sp-card">
              <div class="uc-kpi-rf__dr-h2">
                <div>Cây tác động</div>
                <div class="uc-kpi-rf__legend2">
                  <span><em class="lg2-real"></em>Dữ liệu thật</span>
                  <span><em class="lg2-est"></em>Ước tính (kèm khoảng)</span>
                  <span><em class="lg2-bad"></em>Vượt ngưỡng</span>
                  <span><em class="lg2-good"></em>Đạt ngưỡng</span>
                  <span><em class="lg-w"></em>Độ dày đường = giá trị tiền</span>
                </div>
              </div>
              <svg class="uc-kpi-rf__tree is-big is-v2" :viewBox="'0 0 ' + T.W + ' ' + T.H" preserveAspectRatio="xMidYMin meet" :key="'tree-' + impact.type">
                <text v-for="h in T.heads" :key="h.t" :x="h.x" y="10" class="t-head">{{ h.t }}</text>
                <path v-for="e in T.edges" :key="e.id" :d="e.d" fill="none" :stroke-width="e.w" :class="edgeClass(e)"></path>
                <g v-for="nd in T.nodes" :key="nd.id" :transform="'translate(' + nd.x + ',' + nd.y + ')'" :class="nodeClass(nd)"
                   @mouseenter="impact.hover = nd.id" @mouseleave="impact.hover = ''" @click="impact.hover = nd.id">
                  <rect :width="T.NW" :height="T.NH" class="t-box"></rect>
                  <rect width="4" :height="T.NH" class="t-bar"></rect>
                  <text x="12" y="16" class="t-l" :textLength="nd.label.length > 30 ? T.NW - 20 : null" lengthAdjust="spacingAndGlyphs">{{ nd.label }}</text>
                  <text x="12" y="36" class="t-v" :textLength="nd.v.length > 21 ? T.NW - 20 : null" lengthAdjust="spacingAndGlyphs">{{ nd.v }}</text>
                  <text x="12" y="50" class="t-s" :textLength="(nd.sub || '').length > 36 ? T.NW - 20 : null" lengthAdjust="spacingAndGlyphs">{{ nd.sub }}</text>
                </g>
              </svg>
              <div class="uc-kpi-rf__formula">
                <template v-if="hoverNode"><b>{{ hoverNode.label }}</b> · {{ hoverNode.formula || 'Không có công thức' }} <span class="uc-kpi-rf__src-tag" :class="'src-' + hoverNode.src">{{ srcText[hoverNode.src] }}</span></template>
                <template v-else>Rê chuột (hoặc chạm) vào một ô để xem công thức và đường lan truyền.</template>
              </div>
              <div v-if="cur.dgaps && cur.dgaps.length" class="uc-kpi-rf__gaps"><b>Khoảng trống dữ liệu</b> (chưa tính vào cây): {{ cur.dgaps.join(' · ') }}.</div>
            </section>

            <!-- Value + KPI -->
            <div class="uc-kpi-rf__sp-2col">
              <section class="uc-kpi-rf__sp-card">
                <div class="uc-kpi-rf__dr-h2"><div>Giá trị bị ảnh hưởng</div></div>
                <div class="uc-kpi-rf__sp-value">
                  <div class="uc-kpi-rf__sp-value-total" :class="(cur.strip.now + cur.strip.future) < 0 ? 'tx-bad' : 'tx-good'">{{ signTy(cur.strip.now + cur.strip.future) }}</div>
                  <div class="uc-kpi-rf__sp-value-lbl">tổng doanh thu bị ảnh hưởng</div>
                </div>
                <div class="uc-kpi-rf__vstrip-bar is-big">
                  <span :class="cur.strip.now < 0 ? 'is-neg' : 'is-pos'" :style="{ width: stripPct(cur.strip.now) + '%' }"></span>
                  <span :class="cur.strip.future < 0 ? 'is-neg2' : 'is-pos2'" :style="{ width: stripPct(cur.strip.future) + '%' }"></span>
                </div>
                <div class="uc-kpi-rf__vstrip-lg">
                  <div><em :class="cur.strip.now < 0 ? 'is-neg' : 'is-pos'"></em>Năm nay <b>{{ signTy(cur.strip.now) }}</b></div>
                  <div><em :class="cur.strip.future < 0 ? 'is-neg2' : 'is-pos2'"></em>Các năm sau (ước tính) <b>{{ signTy(cur.strip.future) }}</b></div>
                </div>
              </section>
              <section class="uc-kpi-rf__sp-card">
                <div class="uc-kpi-rf__dr-h2"><div>KPI trước và sau, so với ngưỡng</div></div>
                <div class="uc-kpi-rf__tbars">
                  <div v-for="b in cur.bars" :key="b.k" class="uc-kpi-rf__tbar">
                    <div class="uc-kpi-rf__tbar-l">{{ b.k }}</div>
                    <div class="uc-kpi-rf__tbar-t is-big">
                      <span class="is-before" :style="{ width: Math.min(100, b.b / b.max * 100) + '%' }"></span>
                      <span class="is-after" :class="'st-' + b.st" :style="{ width: Math.min(100, b.a / b.max * 100) + '%' }"></span>
                      <i :style="{ left: Math.min(100, b.t / b.max * 100) + '%' }" :title="'Đích ' + fmtPct(b.t, 0)"></i>
                    </div>
                    <div class="uc-kpi-rf__tbar-v"><s>{{ fmtPct(b.b, 1) }}</s> → <b>{{ fmtPct(b.a, 1) }}</b><small>ngưỡng {{ b.better === 'down' ? '≤' : '' }}{{ fmtPct(b.t, 1) }}</small></div>
                  </div>
                </div>
              </section>
            </div>

            <!-- Why + who -->
            <div class="uc-kpi-rf__sp-2col">
              <section class="uc-kpi-rf__sp-card">
                <div class="uc-kpi-rf__dr-h2"><div>{{ cur.whyTitle }}</div></div>
                <template v-if="impact.type === 'rut'">
                  <div class="uc-kpi-rf__route">
                    <div><span>Giải trình (luôn là)</span><b>{{ icRut.u.owner }}</b></div>
                    <div><span>Xử lý nguyên nhân</span><b>{{ icRut.route.owner }}</b></div>
                    <div><span>Chỉ số cần soi tiếp</span><b>{{ icRut.route.watch }}</b></div>
                    <div><span>Hành động đề xuất</span><b>{{ icRut.route.act }}</b></div>
                  </div>
                  <div class="uc-kpi-rf__dr-note">Thực tế lũy kế <b>toàn hệ thống</b> (chưa tách theo đơn vị): {{ reasonsInline }}.</div>
                </template>
                <template v-else>
                  <div v-for="(d, i) in cur.why" :key="'w' + i" class="uc-kpi-rf__drv">
                    <div class="uc-kpi-rf__drv-l">{{ d.k }}<small v-if="d.note">{{ d.note }}</small></div>
                    <div class="uc-kpi-rf__drv-v"><b :class="d.bad ? 'tx-bad' : ''">{{ d.v }}</b></div>
                    <div class="uc-kpi-rf__drv-o">{{ d.o }}</div>
                  </div>
                  <div v-if="cur.whyNote" class="uc-kpi-rf__dr-note">{{ cur.whyNote }}</div>
                </template>
              </section>
              <section class="uc-kpi-rf__sp-card">
                <div class="uc-kpi-rf__dr-h2"><div>Ai phải làm gì</div></div>
                <div v-for="(w, i) in cur.who" :key="'o' + i" class="uc-kpi-rf__who"><b>{{ w.o }}</b><span>{{ w.a }}</span></div>
              </section>
            </div>

            <!-- Detail -->
            <button type="button" class="uc-kpi-rf__detailbtn" @click="impact.showDetail = !impact.showDetail">{{ impact.showDetail ? 'Ẩn bảng chi tiết' : 'Xem bảng chi tiết từng chỉ số' }}</button>
            <div v-if="impact.showDetail" class="uc-kpi-rf__sp-2col is-3">
              <section v-for="(ring, ri) in cur.rings" :key="'ring' + ri" class="uc-kpi-rf__sp-card">
                <div class="uc-kpi-rf__dr-h2"><div>{{ ring.t }}</div></div>
                <div v-for="(x, i) in ring.items" :key="'x' + i" class="uc-kpi-rf__imp" :class="{ 'is-flag': x.flag, 'is-good': x.good }">
                  <div class="uc-kpi-rf__imp-l">{{ x.k }}<small v-if="x.note">{{ x.note }}</small></div>
                  <div class="uc-kpi-rf__imp-v">
                    <template v-if="x.from !== undefined"><s>{{ x.from }}</s> → <b>{{ x.to }}</b></template>
                    <b v-else :class="x.bad ? 'tx-bad' : (x.pos ? 'tx-good' : '')">{{ x.v }}</b>
                  </div>
                  <span class="uc-kpi-rf__src-tag" :class="'src-' + x.src">{{ srcText[x.src] }}</span>
                </div>
              </section>
            </div>
            <div class="uc-kpi-rf__dr-foot">
              Phương pháp: cây giá trị lan truyền xuôi từ sự kiện; mọi giả định được công khai, số ước tính kèm khoảng giá trị.
              Để tính đủ các vòng cần <b>một mã học sinh chung</b> nối ME, thu phí, dịch vụ và CRM.
            </div>
          </main>
        </div>
      </div>
    </div>

    <!-- ================= BOARD PACK (print / PDF) ================= -->
    <Teleport to="body"><div v-if="printing" class="uc-kpi-rf__pack">
      <!-- Page 1 -->
      <section class="pk-page">
        <div class="pk-head">
          <div>
            <div class="pk-org">Hệ thống Trường Song ngữ Lạc Hồng · LHBS</div>
            <div class="pk-title">Báo cáo Hội đồng trường · Tháng 9/2026</div>
            <div class="pk-sub">Board Report · Năm học 2026–2027 · Chốt dữ liệu 30/09/2026</div>
          </div>
          <div class="pk-stamp">BẢN NHÁP<br><small>Số liệu chưa xác minh</small></div>
        </div>

        <h2 class="pk-h">1. Kết luận <i>Executive summary · {{ narrative.t }}</i></h2>
        <div class="pk-lead">
          Sĩ số đạt <b>{{ fmtPct(all.pct, 1) }}</b> chỉ tiêu, thiếu <b>{{ fmtInt(all.gap) }} học sinh</b> (≈ {{ fmtTy(all.vGap) }} doanh thu còn lại năm học, ước tính).
          {{ weakUnitsText }}
          Chuyển đổi tuyển sinh <b>{{ fmtPct(funnelAll.conv, 1) }}</b> so với đích 30%.
          Có <b>{{ highRiskCount }} rủi ro mức cao</b>.
          <b>{{ kpiCount['Chưa đủ dữ liệu'] }}/{{ strategicKpis.length }}</b> KPI chiến lược chưa đo được.
        </div>

        <table class="pk-stats">
          <tr>
            <td><span>Sĩ số / chỉ tiêu</span><b>{{ fmtInt(all.t9) }} / {{ fmtInt(all.kh) }}</b><small>{{ fmtPct(all.pct, 1) }} · {{ signed(all.t9 - all.t8, 0) }} so với T8</small></td>
            <td><span>Học sinh còn thiếu</span><b>{{ fmtInt(all.gap) }}</b><small>≈ {{ fmtTy(all.vGap) }} doanh thu (ước tính)</small></td>
            <td><span>Rút hồ sơ lũy kế · KPI 3</span><b>{{ all.di }} HS · {{ fmtPct(all.rut, 1) }}</b><small>Nhịp đích {{ fmtPct(rutPace, 1) }} sau 2 tháng</small></td>
          </tr>
          <tr>
            <td><span>Chuyển đổi tuyển sinh · KPI 5</span><b>{{ fmtPct(funnelAll.conv, 1) }}</b><small>{{ funnelAll.nh }}/{{ funnelAll.leads }} lead T8–T9 · đích 30%</small></td>
            <td><span>Biến động nhân sự T9</span><b>+{{ hr.in9 }} / −{{ hr.out9 }}</b><small>4 GV thử việc nghỉ</small></td>
            <td><span>Cảnh báo y tế</span><b>30 ca tay chân miệng</b><small>MN Trấn Biên · 0 tai nạn thương tích</small></td>
          </tr>
        </table>

        <h2 class="pk-h">2. Trách nhiệm giải trình theo đơn vị <i>Accountability</i></h2>
        <table class="pk-table">
          <thead><tr><th class="l">Đơn vị</th><th>Sĩ số / chỉ tiêu</th><th>Rút lũy kế</th><th>Chuyển đổi</th><th>CLB / chỉ tiêu</th><th>Thiếu (DT, ước tính)</th><th class="l">Kết luận</th></tr></thead>
          <tbody>
            <tr v-for="r in unitRows" :key="'pk' + r.k">
              <td class="l"><b>{{ r.ten }}</b><small>{{ r.owner }}</small></td>
              <td :class="'pk-' + statusPct(r.pct)">{{ fmtPct(r.pct, 1) }}<small>{{ r.t9 }}/{{ r.kh }}</small></td>
              <td :class="'pk-' + statusRut(r)">{{ fmtPct(r.rut, 1) }}<small>{{ r.di }} HS</small></td>
              <td :class="'pk-' + statusConv(r.fn.conv)">{{ fmtPct(r.fn.conv, 1) }}<small>{{ r.fn.label }}</small></td>
              <td :class="'pk-' + statusPct(r.clbPct)">{{ fmtPct(r.clbPct, 0) }}</td>
              <td>{{ fmtTy(r.vGap) }}</td>
              <td class="l"><b :class="r.mustExplain ? 'pk-txt-bad' : ''">{{ r.mustExplain ? 'Cần giải trình' : 'Theo dõi' }}</b></td>
            </tr>
          </tbody>
        </table>
        <div class="pk-note">Ngưỡng: sĩ số ≥95% đạt · 90–95% theo dõi · &lt;90% đỏ. Rút lũy kế so với nhịp 10%/năm. Chuyển đổi ≥30% đạt · &lt;20% đỏ. Chuyển đổi Liên cấp chưa tách theo cấp.</div>
      </section>

      <!-- Page 2 -->
      <section class="pk-page pk-break">
        <h2 class="pk-h">3. Rủi ro và cảnh báo <i>Risk register</i></h2>
        <table class="pk-table">
          <thead><tr><th class="l">Mức</th><th class="l">Rủi ro</th><th class="l">Mô tả</th><th class="l">Phụ trách</th></tr></thead>
          <tbody>
            <tr v-for="(r, i) in risks" :key="'pr' + i">
              <td class="l"><b :class="r.level === 'cao' ? 'pk-txt-bad' : ''">{{ r.level === 'cao' ? 'Cao' : (r.level === 'tb' ? 'Trung bình' : 'Thấp') }}</b></td>
              <td class="l"><b>{{ r.title }}</b></td>
              <td class="l">{{ r.detail }}</td>
              <td class="l">{{ r.owner }}</td>
            </tr>
          </tbody>
        </table>

        <h2 class="pk-h">4. Bộ KPI chiến lược <i>Strategic KPIs · đánh giá NH 2025–2026</i></h2>
        <div class="pk-kpisum">
          <span v-for="s in kpiStatusOrder" :key="'ps' + s">{{ s }}: <b>{{ kpiCount[s] }}</b></span>
        </div>
        <table class="pk-table">
          <thead><tr><th class="l">Mã</th><th class="l">KPI</th><th class="l">Số liệu T9/2026</th><th class="l">Đánh giá</th><th class="l">Đơn vị sở hữu</th></tr></thead>
          <tbody>
            <tr v-for="k in topKpis" :key="'pk' + k.code">
              <td class="l"><b>{{ k.code }}</b></td><td class="l">{{ k.name }}</td><td class="l">{{ k.t9 || '—' }}</td><td class="l"><b>{{ k.status }}</b></td><td class="l">{{ k.owner }}</td>
            </tr>
          </tbody>
        </table>
        <div class="pk-note">Mã KPI theo MASTER KPI LHBS (khung Results Framework), trùng bản tổng kết NH 2025–2026; bảng chỉ tiêu của phương án 19/10 ghi khác 4 mã, chờ anh Thái xác nhận bộ mã dùng chung.</div>

        <h2 class="pk-h">5. Độ tin cậy dữ liệu <i>Data assurance</i></h2>
        <div class="pk-kpisum">
          <span>Điểm lệch mới tháng 9: <b>{{ newIssues.length }}</b></span>
          <span>Điểm lệch từ bản tổng kết chờ xác minh: <b>{{ oldIssues.length }}</b></span>
          <span>Định dạng báo cáo khác nhau: <b>4</b></span>
        </div>
        <table class="pk-table">
          <thead><tr><th class="l">Nội dung</th><th class="l">Nguồn 1</th><th class="l">Nguồn 2</th><th class="l">Chênh</th><th class="l">Xác nhận</th></tr></thead>
          <tbody>
            <tr v-for="(d, i) in newIssues.slice(0, 5)" :key="'pi' + i">
              <td class="l"><b>{{ d.n }}</b></td><td class="l">{{ d.a }}</td><td class="l">{{ d.b }}</td><td class="l">{{ d.d }}</td><td class="l">{{ d.o }}</td>
            </tr>
          </tbody>
        </table>
      </section>

      <!-- Page 3 -->
      <section class="pk-page pk-break">
        <h2 class="pk-h">6. Quyết định chờ Hội đồng <i>Decisions requested</i></h2>
        <table class="pk-table pk-decide">
          <thead><tr><th class="l">#</th><th class="l">Đề xuất</th><th class="l">Căn cứ số liệu</th><th>Đồng ý</th><th>Không</th><th class="l">Ý kiến khác</th></tr></thead>
          <tbody>
            <tr v-for="(d, i) in decisions" :key="'pd' + i">
              <td class="l"><b>{{ i + 1 }}</b></td><td class="l"><b>{{ d.t }}</b></td><td class="l">{{ d.e }}</td>
              <td><span class="pk-box"></span></td><td><span class="pk-box"></span></td><td class="pk-blank"></td>
            </tr>
          </tbody>
        </table>

        <h2 class="pk-h">7. Phương pháp và giả định <i>Methodology</i></h2>
        <ul class="pk-ul">
          <li>Nguồn: Dashboard vận hành tháng 9/2026 (Khối Vận hành), báo cáo tháng MN Trấn Biên và MN Long Khánh, Báo cáo tổng kết NH 2025–2026 (bản trình xin ý kiến).</li>
          <li>Số liệu được giữ nguyên theo nguồn; các điểm không khớp được liệt kê ở mục 5, không tự sửa.</li>
          <li>Giá trị VNĐ là <b>ước tính</b> theo các giả định sau, sẽ thay bằng số liệu Kế toán:</li>
        </ul>
        <table class="pk-table pk-assume">
          <tbody><tr v-for="a in assumptions" :key="'pa' + a.k"><td class="l">{{ a.k }}</td><td class="l"><b>{{ a.v }}</b></td></tr></tbody>
        </table>

        <div class="pk-sign">
          <div><span>Người lập</span><i>Ký số trên hệ thống Ký số LHBS</i></div>
          <div><span>Xác nhận số liệu (M&amp;E)</span><i>Ký số trên hệ thống Ký số LHBS</i></div>
          <div><span>Chủ tịch Hội đồng trường</span><i>Ký số trên hệ thống Ký số LHBS</i></div>
        </div>
        <div class="pk-foot">Tài liệu xuất từ hệ thống KPI Results Framework · kyso.lhbs.vn · {{ printedAt }}</div>
      </section>
    </div></Teleport>

    <!-- ================= PAGE 6: BẢN ĐỒ TUYỂN SINH ================= -->
    <div v-if="page === 6" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Bản đồ tuyển sinh · Enrollment map · T8–T9/2026 · {{ unit === 'ALL' ? 'toàn hệ thống' : 'đang làm nổi ' + unitLabel(unit) + ' trên sơ đồ' }}</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">
          {{ fmtInt(mapIn.total) }} lead trong T8–T9 chỉ thành <b>{{ mapIn.nh }} học sinh ({{ fmtPct(mapIn.nh / mapIn.total, 1) }})</b>.
          Điểm nghẽn không nằm ở số lead mà ở <b>khâu giữ liên lạc</b>: {{ fmtInt(mapIn.kll) }} lead ({{ fmtPct(mapIn.kll / mapIn.total, 0) }}) không liên lạc được, gấp {{ fmtNum(mapIn.kll / mapIn.nh, 1) }} lần số nhập học.
          Ở chiều ra, {{ mapOut.total }} học sinh rút, {{ fmtPct(mapOut.noiO / mapOut.total, 0) }} vì nơi ở / đưa đón, và <b>chưa ca nào ghi trường chuyển đến</b>, nên chưa biết đang mất học sinh vào tay ai.
        </div>
      </div>

      <div class="uc-kpi-rf__stats">
        <div v-for="s in mapStats" :key="s.k" :class="['uc-kpi-rf__stat', 'is-click', s.cls, { 'is-focus': mapActive === s.focus && s.focus }]" @click="mapFocus(s.flow, s.focus)" :title="'Xem trên sơ đồ ' + (s.flow === 'in' ? 'dòng vào' : 'dòng ra')">
          <div class="uc-kpi-rf__stat-k">{{ s.k }}</div>
          <div class="uc-kpi-rf__stat-v">{{ s.v }} <small v-if="s.u">{{ s.u }}</small></div>
          <div class="uc-kpi-rf__stat-d">{{ s.d }}</div>
        </div>
      </div>

      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__seg uc-kpi-rf__flowseg">
              <button type="button" :class="{ 'is-on': map.flow === 'in' }" @click="mapFocus('in', '')">Dòng vào · {{ fmtInt(mapIn.total) }} lead</button>
              <button type="button" :class="{ 'is-on': map.flow === 'out' }" @click="mapFocus('out', '')">Dòng ra · {{ mapOut.total }} học sinh rút</button>
            </div>
            <div class="uc-kpi-rf__vtitle uc-kpi-rf__flowt">{{ map.flow === 'in' ? 'Kênh nguồn → Đơn vị → Kết quả' : 'Đơn vị → Rút học → Lý do → Nơi đến' }} <span class="uc-kpi-rf__en">{{ map.flow === 'in' ? 'Admissions flow' : 'Attrition & destination' }}</span></div>
            <div class="uc-kpi-rf__legend2">
              <span><em :class="['lg-flow', { 'is-out': map.flow === 'out' }]"></em>Dữ liệu thật</span>
              <span v-if="map.flow === 'in'"><em class="lg-flow is-est"></em>Phân bổ ước tính</span>
              <span v-else><em class="lg-ph"></em>Chưa có dữ liệu</span>
              <span>Độ dày = số {{ map.flow === 'in' ? 'lead' : 'học sinh' }}</span>
            </div>
          </div>
          <svg class="uc-kpi-rf__sankey" :viewBox="'0 0 ' + mapS.W + ' ' + mapS.H" preserveAspectRatio="xMidYMid meet" @mouseleave="map.hover = ''">
            <defs>
              <pattern v-for="h in mapHatch" :key="h.k" :id="'ukh-' + h.k" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(45)">
                <rect width="6" height="6" :fill="h.c" fill-opacity="0.07" />
                <line x1="0" y1="0" x2="0" y2="6" :stroke="h.c" stroke-width="2.2" stroke-opacity="0.5" />
              </pattern>
            </defs>
            <text v-for="h in mapS.heads" :key="'h' + h.t" class="s-head" :x="h.x" y="12" :text-anchor="h.a">{{ h.t }}</text>
            <path v-for="(l, i) in mapS.links" :key="map.flow + i" :d="l.d" :class="mapLinkClass(l)" :style="l.est ? { fill: 'url(#ukh-' + l.tone + ')' } : null" />
            <g v-for="n in mapS.nodes" :key="n.id" :class="mapNodeClass(n)" @mouseenter="map.hover = n.id" @click="map.hover = n.id">
              <rect v-if="n.ph" :x="n.x + mapS.nw / 2 - 1" :y="n.y" width="2" :height="n.h" />
              <rect v-else :x="n.x" :y="n.y" :width="mapS.nw" :height="n.h" />
              <text :x="n.lx" :y="n.ly" :text-anchor="n.la" class="s-l">{{ n.label }} <tspan class="s-v">{{ n.ph ? '?' : fmtInt(n.val) }}</tspan></text>
            </g>
          </svg>
          <div v-if="mapNote(mapS)" class="uc-kpi-rf__formula">{{ mapNote(mapS) }}</div>
          <div class="uc-kpi-rf__src">
            <template v-if="map.flow === 'in'">Nguồn: Excel vận hành T9, sheet "8. Tư vấn tuyển sinh". Lý do thất bại Mầm non chỉ có tổng 2 cơ sở; phần chia cho từng cơ sở (sọc chéo) là ước tính theo số lead chưa nhập học. MN Long Khánh chỉ ghi nguồn Facebook.</template>
            <template v-else>Nguồn: Excel vận hành, lũy kế đầu năm học đến T9. Lý do rút mới có tổng toàn hệ thống, nên dùng ô trung gian "Rút học". Mọi dòng ra đổ về "Chưa ghi trường đến"; các vạch đứt là nơi đến mà phiếu rút hồ sơ cần ghi được.</template>
            Rê chuột hoặc chạm vào một nút để xem chi tiết.
          </div>
        </div>

          <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
            <div class="uc-kpi-rf__vhead">
              <div class="uc-kpi-rf__vtitle">Chuyển cấp nội bộ <span class="uc-kpi-rf__en">Internal feeder</span></div>
              <div class="uc-kpi-rf__vnote">Tỷ lệ lên cấp chưa theo dõi</div>
            </div>
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain">
              <thead><tr><th class="ta-l">Mốc</th><th>HS cuối cấp</th><th class="ta-l">Tỷ lệ lên cấp thực tế</th></tr></thead>
              <tbody>
                <tr v-for="f in mapFeeder" :key="f.k">
                  <td class="ta-l"><b>{{ f.t }}</b><small>{{ f.sub }}</small></td>
                  <td><b>{{ fmtInt(f.base) }}</b><small class="bm-that">thật · T9</small></td>
                  <td class="ta-l"><span class="uc-kpi-rf__src-tag src-chua">Chưa có dữ liệu</span></td>
                </tr>
              </tbody>
            </table>
            <div class="uc-kpi-rf__src">Khối 1 nhận {{ mapK1Den }} HS chuyển đến nhưng chưa tách được bao nhiêu em từ mầm non LHBS lên. Cần mã học sinh chung Mầm non – Liên cấp. Muốn thử tỷ lệ lên cấp, xem tab Mô phỏng kịch bản.</div>
          </div>
          <div class="uc-kpi-rf__visual uc-kpi-rf__span5 uc-kpi-rf__empty">
            <div class="uc-kpi-rf__vhead">
              <div class="uc-kpi-rf__vtitle">Bản đồ địa lý <span class="uc-kpi-rf__en">Catchment</span></div>
              <div class="uc-kpi-rf__vnote">Chưa có dữ liệu</div>
            </div>
            <div class="uc-kpi-rf__mapev">
              <div><b>{{ mapOut.noiO }}/{{ mapOut.total }}</b><span>HS rút vì nơi ở / đưa đón</span></div>
              <div><b>{{ mapBusLead }}</b><span>lead rơi vì ngoài tuyến xe</span></div>
            </div>
            <div class="uc-kpi-rf__src">Cần phường/xã trên phiếu lead và hồ sơ học sinh để thấy vùng có lead nhưng chưa có tuyến xe, vùng học sinh rút tập trung, vị trí trường cạnh tranh.</div>
          </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Dữ liệu đang ở đâu <span class="uc-kpi-rf__en">Data readiness</span></div>
            <div class="uc-kpi-rf__legend2">
              <span><svg class="uc-kpi-rf__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /><circle cx="6" cy="6" r="5" class="hb-f" /></svg>Có</span>
              <span><svg class="uc-kpi-rf__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /><path d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" /></svg>Một phần</span>
              <span><svg class="uc-kpi-rf__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /></svg>Chưa có</span>
            </div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__table--wrap">
              <thead><tr><th class="ta-l">Câu hỏi quản trị</th><th class="ta-l">Đang nằm ở đâu</th><th class="ta-l">Còn thiếu</th><th class="ta-l">Chủ sở hữu</th><th class="ta-l">Thu ở đâu</th></tr></thead>
              <tbody>
                <tr v-for="r in mapReady" :key="r.q">
                  <td class="ta-l uc-kpi-rf__hbcell">
                    <svg class="uc-kpi-rf__hb" viewBox="0 0 12 12">
                      <circle cx="6" cy="6" r="5" class="hb-o" />
                      <circle v-if="r.st === 'good'" cx="6" cy="6" r="5" class="hb-f" />
                      <path v-if="r.st === 'part'" d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" />
                    </svg><b>{{ r.q }}</b>
                  </td>
                  <td class="ta-l">{{ r.where }}</td>
                  <td class="ta-l">{{ r.miss }}</td>
                  <td class="ta-l">{{ r.owner }}</td>
                  <td class="ta-l">{{ r.cap }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__fieldlist">
            <p><b>Phiếu lead, 6 trường:</b> {{ mapFieldsLead.join(' · ') }}.</p>
            <p><b>Phiếu rút hồ sơ, 3 trường:</b> {{ mapFieldsOut.join(' · ') }}.</p>
            <p class="tx-muted">Thu đủ 9 trường này từ đầu là vẽ được cả 4 lớp bản đồ, chưa cần CRM tuyển sinh hoàn chỉnh.</p>
          </div>
        </div>
      </div>
    </div>

    <!-- ================= PAGE 7: ĐỐI SÁNH KHU VỰC ================= -->
    <div v-if="page === 7" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Đối sánh khu vực · Competitive benchmark · {{ bmLevelName }} · {{ bmPeers.length }} trường cùng phân khúc</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">
          <template v-if="bmPeers.length < 3">Ở cấp {{ bmLevelName }}, học phí LHBS là {{ fmtNum(bmSelf.fee, 1) }} triệu/năm nhưng mới có {{ bmPeers.length }} trường đối thủ có học phí công bố, <b>chưa đủ để so sánh</b>.</template>
          <template v-else>          Ở cấp {{ bmLevelName }}, học phí LHBS ({{ fmtNum(bmSelf.fee, 1) }} triệu/năm) <b>{{ bmSelf.fee >= bmMed.fee ? 'cao hơn' : 'thấp hơn' }} {{ fmtPct(Math.abs(bmSelf.fee / bmMed.fee - 1), 0) }}</b> so với trung vị nhóm ({{ fmtNum(bmMed.fee, 1) }} triệu),
          <template v-if="Math.abs(bmSelf.q - bmMed.q) >= 5">trong khi chỉ số đầu ra giả định {{ bmSelf.q >= bmMed.q ? 'cao hơn' : 'thấp hơn' }} trung vị {{ Math.abs(bmSelf.q - bmMed.q) }} điểm, nên LHBS đang ở ô <b>"{{ bmQuad(bmSelf).t }}"</b>.</template>
          <template v-else>nhưng trục đầu ra mới là giả định và đang ngang trung vị, nên <b>chưa đủ căn cứ để xếp ô định vị</b>. Số thật đã có của LHBS: trúng tuyển đại học 154/156 (98,7%), tốt nghiệp THPT 100% năm 2024–25.</template></template>
          Học phí của {{ bmCount.cong }} trường lấy từ biểu phí và báo cáo công khai trên website trường (26/10/2026); {{ bmCount.none }} trường chưa công bố hoặc chưa xác minh nên không đưa vào so sánh. Chỉ số đầu ra vẫn là giả định.
          Toàn dashboard quy đổi tiền theo học phí niêm yết 2026 của LHBS từng cấp (trước đây giả định 110–180 triệu).
        </div>
      </div>

      <div class="uc-kpi-rf__bmbar">
        <div>
          <div class="uc-kpi-rf__slicer-label">Cấp học so sánh</div>
          <div class="uc-kpi-rf__seg">
            <button v-for="o in bmLevels" :key="o.k" type="button" :class="{ 'is-on': bmLevel === o.k }" @click="bm.level = o.k">{{ o.t }}</button>
          </div>
        </div>
        <div class="uc-kpi-rf__legend2">
          <span><em class="lg-src cong"></em>Công bố chính thức</span>
          <span><em class="lg-src tong"></em>Tổng hợp từ web</span>
          <span><em class="lg-src gia"></em>Giả định</span>
        </div>
      </div>

      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Bản đồ định vị · Học phí × Đầu ra <span class="uc-kpi-rf__en">Positioning map</span></div>
            <div class="uc-kpi-rf__vnote">Trục ngang thang log · bong bóng = quy mô HS</div>
          </div>
          <svg class="uc-kpi-rf__pos" :viewBox="'0 0 ' + bmMap.W + ' ' + bmMap.H" preserveAspectRatio="xMidYMid meet" @mouseleave="bm.hover = ''">
            <rect :x="bmMap.L" :y="bmMap.T" :width="bmMap.pw" :height="bmMap.ph" class="p-bg" />
            <line v-for="t in bmMap.xt" :key="'x' + t.v" :x1="t.x" :x2="t.x" :y1="bmMap.T" :y2="bmMap.T + bmMap.ph" class="p-grid" />
            <text v-for="t in bmMap.xt" :key="'xl' + t.v" :x="t.x" :y="bmMap.T + bmMap.ph + 14" text-anchor="middle" class="p-ax">{{ t.v }}</text>
            <line v-for="t in bmMap.yt" :key="'y' + t.v" :x1="bmMap.L" :x2="bmMap.L + bmMap.pw" :y1="t.y" :y2="t.y" class="p-grid" />
            <text v-for="t in bmMap.yt" :key="'yl' + t.v" :x="bmMap.L - 6" :y="t.y + 3" text-anchor="end" class="p-ax">{{ t.v }}</text>
            <line :x1="bmMap.mx" :x2="bmMap.mx" :y1="bmMap.T" :y2="bmMap.T + bmMap.ph" class="p-med" />
            <line :x1="bmMap.L" :x2="bmMap.L + bmMap.pw" :y1="bmMap.my" :y2="bmMap.my" class="p-med" />
            <text v-for="q in bmMap.quads" :key="q.t" :x="q.x" :y="q.y" :text-anchor="q.a" class="p-quad">{{ q.t }}</text>
            <text :x="bmMap.L + bmMap.pw" :y="bmMap.T + bmMap.ph + 28" text-anchor="end" class="p-axt">Học phí tham chiếu, triệu đồng/năm →</text>
            <text :x="bmMap.L - 34" :y="bmMap.T + bmMap.ph / 2" text-anchor="middle" class="p-axt" :transform="'rotate(-90 ' + (bmMap.L - 34) + ' ' + (bmMap.T + bmMap.ph / 2) + ')'">Chỉ số đầu ra (giả định) →</text>
            <g v-for="p in bmMap.pts" :key="p.k" :class="['p-pt', 'is-' + p.feeSrc, { 'is-self': p.self, 'is-dim': bm.hover && bm.hover !== p.k }]" @mouseenter="bm.hover = p.k" @click="bm.hover = p.k">
              <circle :cx="p.x" :cy="p.y" :r="p.r" />
              <line v-if="p.lead" :x1="p.lead.x1" :y1="p.lead.y1" :x2="p.lead.x2" :y2="p.lead.y2" class="p-lead" />
              <text :x="p.lx" :y="p.ly" :text-anchor="p.la" class="p-l">{{ p.short }}</text>
            </g>
          </svg>
          <div v-if="bmHoverRow" class="uc-kpi-rf__formula">
            <b>{{ bmHoverRow.t }}</b> · {{ bmHoverRow.prog }} · học phí {{ fmtNum(bmHoverRow.fee, bmHoverRow.fee < 100 ? 1 : 0) }} triệu/năm ({{ bmSrcText[bmHoverRow.feeSrc] }}{{ bmHoverRow.feeNote ? ': ' + bmHoverRow.feeNote : '' }}) · quy mô ~{{ fmtInt(bmHoverRow.hs) }} HS ({{ bmHoverRow.hsNote || bmSrcText[bmHoverRow.hsSrc] }}) · đầu ra {{ bmHoverRow.q }}/100
          </div>
          <div class="uc-kpi-rf__src">Đường đứt: trung vị nhóm. Chỉ số đầu ra là thang 0–100 giả định, sẽ thay bằng điểm thi vào 10, tốt nghiệp THPT, IELTS (Sở GD&amp;ĐT công bố) khi có. Rê chuột vào bong bóng để xem chi tiết.</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">LHBS so với trung vị nhóm <span class="uc-kpi-rf__en">vs peer median</span></div>
            <div class="uc-kpi-rf__vnote">{{ bmLevelName }}</div>
          </div>
          <div class="uc-kpi-rf__bmrank">
            <div v-for="m in bmRank" :key="m.k" class="uc-kpi-rf__bmrank-row">
              <div class="uc-kpi-rf__bmrank-l">{{ m.t }}<small>{{ m.sub }}</small></div>
              <div class="uc-kpi-rf__bmrank-t">
                <span class="is-range" :style="{ left: m.minP + '%', width: (m.maxP - m.minP) + '%' }"></span>
                <i class="is-med" :style="{ left: m.medP + '%' }"></i>
                <b class="is-self" :style="{ left: m.selfP + '%' }"></b>
              </div>
              <div class="uc-kpi-rf__bmrank-v"><b>{{ m.selfTxt }}</b><small>trung vị {{ m.medTxt }}</small></div>
            </div>
          </div>
          <div class="uc-kpi-rf__bmkey"><span><em class="k-range"></em>Khoảng nhóm (thấp nhất – cao nhất)</span><span><em class="k-med"></em>Trung vị</span><span><em class="k-self"></em>LHBS</span></div>
          <div class="uc-kpi-rf__callout">{{ bmQuad(bmSelf).msg }}</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span12">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Nhóm đối thủ trực tiếp <span class="uc-kpi-rf__en">Peer set</span></div>
            <div class="uc-kpi-rf__vnote">Thu từ website và báo cáo công khai của trường, 26/10/2026 · cần tư vấn viên xác nhận danh sách</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__table--plain uc-kpi-rf__bmtable">
              <thead><tr><th class="ta-l">Trường</th><th class="ta-l">Cấp học</th><th class="ta-l">Chương trình</th><th>Học phí {{ bmLevelName }}</th><th>Quy mô</th><th>Đầu ra</th><th class="ta-l">Cạnh tranh với</th><th class="ta-l">Nguồn học phí</th></tr></thead>
              <tbody>
                <tr v-for="p in bmTable" :key="p.k" :class="{ 'is-self': p.self, 'is-off': !p.has }" @mouseenter="bm.hover = p.k" @mouseleave="bm.hover = ''">
                  <td class="ta-l"><b>{{ p.t }}</b><small>{{ p.area }}</small></td>
                  <td class="ta-l"><span v-for="l in bmLevels" :key="l.k" :class="['uc-kpi-rf__lvdot', { 'is-on': p.lv.indexOf(l.k) >= 0 }]">{{ l.s }}</span></td>
                  <td class="ta-l">{{ p.prog }}</td>
                  <td><template v-if="p.has"><b>{{ fmtNum(p.fee, p.fee < 100 ? 1 : 0) }}</b><small :class="'bm-' + p.feeSrc">{{ bmSrcText[p.feeSrc] }}</small></template><span v-else :class="p.lvHas ? 'bm-gia' : 'tx-muted'">{{ p.lvHas ? 'Chưa công bố' : 'không có cấp này' }}</span></td>
                  <td><template v-if="p.lvHas">{{ fmtInt(p.hs) }}<small :class="'bm-' + p.hsSrc">{{ bmSrcText[p.hsSrc] }}</small></template><span v-else class="tx-muted">—</span></td>
                  <td>{{ p.q }}<small :class="p.self ? 'bm-gia' : 'bm-gia'">giả định</small></td>
                  <td class="ta-l">{{ p.vs }}</td>
                  <td class="ta-l uc-kpi-rf__bmsrc">{{ p.feeNote || '—' }}</td>
                </tr>
              </tbody>
            </table>
          </div>
          <div class="uc-kpi-rf__src">Học phí quy về triệu đồng/năm, chưa gồm bán trú, xe, đồng phục: số theo tháng quy đổi × 9 tháng (phổ thông, theo cách IGC công bố) hoặc × 12 (mầm non); số đã gồm bán trú thì trừ phần bán trú. Trường chưa công bố học phí không đưa vào bản đồ và trung vị. Học phí LHBS lấy từ trang học phí niêm yết 2026, đối chiếu khớp báo cáo thường niên 2024–25. Quy mô và đầu ra của trường khác là giả định để dựng khung, không dùng để kết luận về trường đó.</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Đang thua ai · Minh họa <span class="uc-kpi-rf__en">Win / loss</span></div>
            <span class="uc-kpi-rf__src-tag src-chua">Minh họa, chưa có dữ liệu</span>
          </div>
          <div class="uc-kpi-rf__hbars">
            <div v-for="w in bmLoss" :key="w.k" class="uc-kpi-rf__hbar">
              <div class="uc-kpi-rf__hbar-l">{{ w.t }}</div>
              <div class="uc-kpi-rf__hbar-t"><span class="is-hatch" :style="{ width: (w.n / bmLossMax * 100) + '%' }"></span></div>
              <div class="uc-kpi-rf__hbar-n">{{ w.n }}</div>
            </div>
          </div>
          <div class="uc-kpi-rf__src">Phân bổ giả định {{ mapOut.total }} HS rút theo nơi đến để minh họa bảng sẽ trông thế nào. Thực tế hiện 0/{{ mapOut.total }} ca ghi trường chuyển đến. Có trường "Trường chuyển đến" trên phiếu rút và "Trường đã chọn" trên lead rơi là bảng này thành số thật.</div>
        </div>

        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Thu dữ liệu đối sánh <span class="uc-kpi-rf__en">Data plan</span></div>
          </div>
          <div class="uc-kpi-rf__bmplan">
            <div v-for="d in bmPlan" :key="d.t">
              <b>{{ d.t }}</b>
              <span>{{ d.what }}</span>
              <small>{{ d.who }} · {{ d.when }}</small>
            </div>
          </div>
          <div class="uc-kpi-rf__src">Chỉ thu thông tin các trường công bố cho phụ huynh. Không thu dữ liệu cá nhân, không giả danh để lấy thông tin nội bộ.</div>
        </div>
      </div>
    </div>

    <!-- ================= PAGE 8: VẬN HÀNH ƯU TIÊN ================= -->
    <div v-if="page === 8" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Vận hành ưu tiên · độ phủ dữ liệu của {{ kpiDict.length }} chỉ số vận hành</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">{{ covHeadline }}</div>
      </div>

      <div class="uc-kpi-rf__covsum">
        <div v-for="g in covGroups" :key="g.k" class="uc-kpi-rf__covg">
          <div class="cv-h"><b>{{ g.t }}</b><span>{{ g.good + g.part }}/{{ g.items.length }} có dữ liệu</span></div>
          <div class="cv-bar"><i class="is-good" :style="{ width: g.good / g.items.length * 100 + '%' }"></i><i class="is-part" :style="{ width: g.part / g.items.length * 100 + '%' }"></i></div>
          <div class="cv-l"><span><i class="is-good"></i>Có {{ g.good }}</span><span><i class="is-part"></i>Một phần {{ g.part }}</span><span><i></i>Chưa có {{ g.none }}</span></div>
        </div>
      </div>

      <div class="uc-kpi-rf__visual">
        <div class="uc-kpi-rf__vhead">
          <div class="uc-kpi-rf__vtitle">Ma trận sẵn sàng dữ liệu <span class="uc-kpi-rf__en">Data coverage matrix</span></div>
          <div class="uc-kpi-rf__vnote">Bấm một dòng để xem định nghĩa trong Từ điển KPI</div>
        </div>
        <div class="uc-kpi-rf__tablewrap">
          <table class="uc-kpi-rf__table uc-kpi-rf__table--wrap uc-kpi-rf__covt">
            <thead><tr><th class="ta-l">Chỉ số</th><th class="ta-l">Dữ liệu T9</th><th class="ta-l">Cách thu hiện tại → đích</th><th class="ta-l">Tách theo cơ sở</th><th class="ta-l">Mục tiêu</th><th class="ta-l">Phụ trách</th></tr></thead>
            <tbody v-for="g in covGroups" :key="'cg' + g.k">
              <tr class="is-grp"><td colspan="6" class="ta-l"><b>{{ g.t }}</b><span v-for="x in g.sig" :key="x.title" :class="'uc-kpi-rf__covsig lv-' + x.level">Tín hiệu T9: {{ x.title }}</span></td></tr>
              <tr v-for="d in g.items" :key="d.c" class="is-click" @click="openDict(d.c)">
                <td class="ta-l"><b>{{ d.c }}</b> {{ d.n }}</td>
                <td class="ta-l"><span :class="'uc-kpi-rf__cov is-' + d.rd">{{ covText[d.rd] }}</span></td>
                <td class="ta-l">{{ modeText[d.now] }} → {{ modeText[d.goal] }}</td>
                <td class="ta-l">{{ bySite(d) ? 'Có' : 'Chưa' }}</td>
                <td class="ta-l">{{ d.tgt }}</td>
                <td class="ta-l tx-muted">{{ d.own }}</td>
              </tr>
            </tbody>
          </table>
        </div>
        <div class="uc-kpi-rf__src">"Dữ liệu T9": có số trong báo cáo tháng 9 đủ để tính (Có), có một phần hoặc chỉ ở dạng ghi chú (Một phần), chưa có nguồn (Chưa có). Định nghĩa theo phương án ngày 19/10, đang ở trạng thái nháp.</div>
      </div>
    </div>

    <!-- ================= PAGE 9: TỪ ĐIỂN KPI ================= -->
    <div v-if="page === 9" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__bmbar uc-kpi-rf__tierbar">
        <div class="uc-kpi-rf__seg">
          <button type="button" :class="{ 'is-on': dict.tier === 'D' }" @click="dict.tier = 'D'">Tầng D · KPI chiến lược ({{ rfDict.length }})</button>
          <button type="button" :class="{ 'is-on': dict.tier === 'A' }" @click="dict.tier = 'A'">Tầng A · Chỉ số vận hành ({{ kpiDict.length }})</button>
        </div>
        <span class="uc-kpi-rf__tiernote">{{ dict.tier === 'D' ? 'Nguồn: MASTER KPI LHBS (khung Results Framework)' : 'Nguồn: phương án ngày 19/10 (triển khai theo gợi ý chuyên gia KPI)' }}</span>
      </div>

      <template v-if="dict.tier === 'D'">
        <div class="uc-kpi-rf__lead">
          <div class="uc-kpi-rf__lead-k"><span>Từ điển KPI · Tầng D · KPI chiến lược</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
          <div class="uc-kpi-rf__lead-t">
            {{ rfStats.total }} KPI chiến lược, mỗi KPI một phiếu mô tả giữ nguyên định nghĩa, công thức, kỳ chốt và người phụ trách theo MASTER KPI.
            Tiến độ thu baseline 2020–2025 bình quân <b>{{ rfStats.base }}%</b>; {{ rfStats.noOwner }} KPI chưa điền người phụ trách thu dữ liệu; {{ rfStats.review }} KPI có ghi chú rà soát chờ chuyên gia xác nhận.
            Định nghĩa đang ở trạng thái <b>Draft</b>: theo rà soát CSDL, Tầng D chỉ công bố đạt hay không đạt khi định nghĩa đã khóa.
          </div>
        </div>

        <div class="uc-kpi-rf__stats">
          <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">KPI chiến lược</div><div class="uc-kpi-rf__stat-v">{{ rfStats.total }}</div><div class="uc-kpi-rf__stat-d">7 cấp hệ thống · 11 cấp thay đổi ưu tiên</div></div>
          <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Đã có người phụ trách</div><div class="uc-kpi-rf__stat-v">{{ rfStats.total - rfStats.noOwner }} <small>/ {{ rfStats.total }}</small></div><div class="uc-kpi-rf__stat-d">Người xác minh: {{ rfStats.total - rfStats.noVerify }}/{{ rfStats.total }}</div></div>
          <div class="uc-kpi-rf__stat st-l-warn"><div class="uc-kpi-rf__stat-k">Tiến độ thu baseline</div><div class="uc-kpi-rf__stat-v">{{ rfStats.base }}%</div><div class="uc-kpi-rf__stat-d">{{ rfStats.noBase }} KPI ghi "không có dữ liệu baseline"</div></div>
          <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Chỉ số vận hành đã nối</div><div class="uc-kpi-rf__stat-v">{{ rfStats.linked }} <small>/ {{ kpiDict.length }}</small></div><div class="uc-kpi-rf__stat-d">Tầng A đóng góp cho Tầng D</div></div>
          <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Ghi chú rà soát</div><div class="uc-kpi-rf__stat-v">{{ rfStats.review }}</div><div class="uc-kpi-rf__stat-d">KPI có điểm chưa nhất quán trong phiếu</div></div>
          <div class="uc-kpi-rf__stat is-gap"><div class="uc-kpi-rf__stat-k">Đã khóa định nghĩa</div><div class="uc-kpi-rf__stat-v">0 <small>/ {{ rfStats.total }}</small></div><div class="uc-kpi-rf__stat-d">Lộ trình: khóa trong 0–2 tháng</div></div>
        </div>

        <div class="uc-kpi-rf__bmbar">
          <div class="uc-kpi-rf__dictsearch">
            <input type="search" v-model="dict.q" placeholder="Tìm mã, tên KPI, người phụ trách" />
          </div>
        </div>

        <div class="uc-kpi-rf__grid">
          <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
            <div class="uc-kpi-rf__vhead">
              <div class="uc-kpi-rf__vtitle">18 KPI chiến lược <span class="uc-kpi-rf__en">Strategic KPI catalogue</span></div>
              <div class="uc-kpi-rf__vnote">{{ rfRows.length }} KPI · bấm một dòng để xem phiếu</div>
            </div>
            <div class="uc-kpi-rf__tablewrap">
              <table class="uc-kpi-rf__table uc-kpi-rf__dicttable uc-kpi-rf__rftable">
                <thead><tr><th class="ta-l">Mã</th><th class="ta-l">KPI chiến lược</th><th class="ta-l">Kỳ chốt kế tiếp</th><th class="ta-l">Phụ trách thu dữ liệu</th><th class="ta-l">Baseline</th></tr></thead>
                <tbody>
                  <tr v-for="k in rfRows" :key="k.c" :class="{ 'is-sel': dict.selD === k.c }" @click="selectRf(k.c)">
                    <td class="ta-l"><b>{{ k.c }}</b></td>
                    <td class="ta-l"><b>{{ k.n }}</b><small>{{ k.unit || '—' }} · {{ k.out === 'HT' ? 'KPI cấp hệ thống' : 'Thay đổi ưu tiên ' + k.out }}<template v-if="k.review.length"> · <span class="uc-kpi-rf__est">{{ k.review.length }} ghi chú rà soát</span></template></small></td>
                    <td class="ta-l">{{ rfNext(k).d }}<small v-if="rfNext(k).days !== null">còn {{ rfNext(k).days }} ngày</small></td>
                    <td class="ta-l uc-kpi-rf__pool-act"><small class="uc-kpi-rf__owner" :title="k.owner">{{ k.owner }}</small></td>
                    <td class="ta-l"><div class="uc-kpi-rf__minibar"><i :style="{ width: rfBase(k.c) + '%' }"></i></div><small>{{ rfBase(k.c) }}%</small></td>
                  </tr>
                  <tr v-if="!rfRows.length"><td colspan="5" class="ta-l tx-muted">Không có KPI khớp.</td></tr>
                </tbody>
              </table>
            </div>
          </div>

          <div v-if="rfSel" class="uc-kpi-rf__visual uc-kpi-rf__span5 uc-kpi-rf__dictd uc-kpi-rf__rfd">
            <div class="uc-kpi-rf__vhead">
              <div class="uc-kpi-rf__vtitle">{{ rfSel.c }} · {{ rfSel.n }}</div>
              <span class="uc-kpi-rf__tag is-none">Draft · MASTER 2025</span>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Mô tả</h4>
              <dl class="uc-kpi-rf__dl">
                <dt>Định nghĩa</dt><dd>{{ rfSel.def || '—' }}</dd>
                <dt>Tại sao quan trọng</dt><dd>{{ rfSel.why || '—' }}</dd>
                <dt>Khát vọng</dt><dd>{{ rfSel.asp || '—' }}</dd>
              </dl>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Cách tính</h4>
              <dl class="uc-kpi-rf__dl">
                <dt>Đơn vị tính</dt><dd>{{ rfSel.unit || '—' }}</dd>
                <dt>Phương pháp tính</dt><dd>{{ rfSel.method || '—' }}</dd>
                <dt>Phân luồng</dt><dd>{{ rfSel.split || '—' }}</dd>
              </dl>
              <table class="uc-kpi-rf__rfpts">
                <tr v-for="p in rfSel.pts" :key="p.n + p.name"><td>[{{ p.n }}]</td><td><b>{{ p.name }}</b><small>{{ p.desc }}</small></td></tr>
              </table>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Thu thập dữ liệu</h4>
              <dl class="uc-kpi-rf__dl">
                <dt>Kỳ chốt</dt><dd><b>{{ rfNext(rfSel).d }}</b><template v-if="rfNext(rfSel).days !== null"> (còn {{ rfNext(rfSel).days }} ngày)</template><template v-if="rfSel.cutNote"> · {{ rfSel.cutNote }}</template></dd>
                <dt>Tần suất, thời điểm</dt><dd>{{ rfSel.freq || '—' }}</dd>
                <dt>Phương pháp thu</dt><dd>{{ rfSel.collect || '—' }}</dd>
                <dt>Nguồn dữ liệu</dt><dd>{{ rfSel.src || '—' }}</dd>
                <dt>Phụ trách thu</dt><dd :class="{ 'is-muted': rfSel.owner === 'Chưa điền' }">{{ rfSel.owner }}</dd>
                <dt>Nơi lưu trữ</dt><dd>{{ rfSel.store || '—' }}</dd>
              </dl>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Phân tích, xác minh, báo cáo</h4>
              <dl class="uc-kpi-rf__dl">
                <dt>Phân tích</dt><dd>{{ rfSel.analyze || '—' }}</dd>
                <dt>Trình bày</dt><dd>{{ rfSel.present || '—' }}</dd>
                <dt>Xác minh</dt><dd :class="{ 'is-muted': rfSel.verify === 'Chưa điền' }">{{ rfSel.verify }}</dd>
                <dt>Báo cáo</dt><dd>{{ rfSel.report || '—' }}</dd>
              </dl>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Chỉ số vận hành đóng góp (Tầng A)</h4>
              <div v-if="rfOps(rfSel.c).length" class="uc-kpi-rf__rflinks">
                <button v-for="o in rfOps(rfSel.c)" :key="o.c" type="button" @click="openOps(o.c)"><b>{{ o.c }}</b> {{ o.n }}</button>
              </div>
              <div v-else class="tx-muted">Chưa có chỉ số vận hành nối tới KPI này.</div>
            </div>
            <div class="uc-kpi-rf__rfsec">
              <h4>Tiến độ thu baseline 2020–2025</h4>
              <div v-for="b in (rfBaseline[rfSel.c] || [])" :key="b.u" class="uc-kpi-rf__rfbase">
                <span>{{ b.u }}</span>
                <div class="uc-kpi-rf__minibar"><i :style="{ width: b.p + '%' }"></i></div>
                <b>{{ b.p }}%</b>
                <small v-if="b.nb">Không có dữ liệu baseline</small>
              </div>
            </div>
            <div v-if="rfSel.review.length" class="uc-kpi-rf__rfreview">
              <b>Ghi chú rà soát, chờ chuyên gia KPI xác nhận</b>
              <ul><li v-for="r in rfSel.review" :key="r">{{ r }}</li></ul>
            </div>
          </div>
        </div>
        <div class="uc-kpi-rf__src" style="padding-bottom: 8px">Bóc tự động từ MASTER KPI LHBS (các sheet KPI, MA TRAN KET QUA, Baseline Data Contact Points). Không hiển thị họ tên, email, số điện thoại của đầu mối. Kỳ chốt kế tiếp tính từ ngày hôm nay theo mục "Tần suất & thời điểm" của từng phiếu.</div>
      </template>

      <template v-else>
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>Từ điển KPI · KPI dictionary · bản nháp theo Phụ lục 10 báo cáo tổng kết</span><em class="uc-kpi-rf__nar" :title="narrative.note">{{ narrative.t }}</em></div>
        <div class="uc-kpi-rf__lead-t">
          {{ dictStats.total }} chỉ số ưu tiên đã có định nghĩa nháp: tử số, mẫu số, quy tắc, ngày chốt, nguồn, người sở hữu, người kiểm tra, người phê duyệt.
          <b>Chưa chỉ số nào được duyệt.</b> {{ dictStats.tay }}/{{ dictStats.total }} chỉ số hiện vẫn nhập tay; mục tiêu {{ dictStats.goalAuto }} chỉ số lấy tự động hoặc xuất file từ hệ thống.
          Bộ chỉ số vận hành theo phương án 19/10 (triển khai từ gợi ý của anh Thái), tham chiếu KPI chiến lược trong MASTER KPI; 4 mã KPI giữa hai tài liệu <b>chờ anh Thái xác nhận</b>.
        </div>
      </div>

      <div class="uc-kpi-rf__stats">
        <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Chỉ số ưu tiên</div><div class="uc-kpi-rf__stat-v">{{ dictStats.total }}</div><div class="uc-kpi-rf__stat-d">4 nhóm theo phương án 19/10</div></div>
        <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Có đủ công thức</div><div class="uc-kpi-rf__stat-v">{{ dictStats.full }}</div><div class="uc-kpi-rf__stat-d">Tử số, quy tắc, ngày chốt, nguồn</div></div>
        <div class="uc-kpi-rf__stat st-l-warn"><div class="uc-kpi-rf__stat-k">Đang nhập tay</div><div class="uc-kpi-rf__stat-v">{{ dictStats.tay }}</div><div class="uc-kpi-rf__stat-d">Mục tiêu còn {{ dictStats.goalTay }}</div></div>
        <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">Có dữ liệu (đủ / một phần)</div><div class="uc-kpi-rf__stat-v">{{ dictStats.good }} <small>/ {{ dictStats.part }}</small></div><div class="uc-kpi-rf__stat-d">{{ dictStats.none }} chưa có dữ liệu</div></div>
        <div class="uc-kpi-rf__stat is-gap"><div class="uc-kpi-rf__stat-k">Đã duyệt</div><div class="uc-kpi-rf__stat-v">{{ dictStats.duyet }} <small>/ {{ dictStats.total }}</small></div><div class="uc-kpi-rf__stat-d">Chờ thầy Thái, M&amp;E rà soát</div></div>
        <div class="uc-kpi-rf__stat"><div class="uc-kpi-rf__stat-k">IT đề xuất thêm</div><div class="uc-kpi-rf__stat-v">{{ dictStats.add }}</div><div class="uc-kpi-rf__stat-d">Chưa có trong phương án 19/10</div></div>
      </div>

      <div class="uc-kpi-rf__bmbar">
        <div class="uc-kpi-rf__seg">
          <button v-for="o in dictGroups" :key="o.k" type="button" :class="{ 'is-on': dict.grp === o.k }" @click="dict.grp = o.k">{{ o.t }}</button>
        </div>
        <div class="uc-kpi-rf__dictsearch">
          <input type="search" v-model="dict.q" placeholder="Tìm mã, tên, nguồn, người sở hữu" />
          <button type="button" class="uc-kpi-rf__simbtn" @click="exportDict()">Tải CSV để góp ý</button>
        </div>
      </div>

      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Danh mục chỉ số <span class="uc-kpi-rf__en">Catalogue</span></div>
            <div class="uc-kpi-rf__vnote">{{ dictRows.length }} chỉ số · bấm một dòng để xem định nghĩa</div>
          </div>
          <div class="uc-kpi-rf__tablewrap">
            <table class="uc-kpi-rf__table uc-kpi-rf__dicttable">
              <thead><tr><th class="ta-l">Mã</th><th class="ta-l">Chỉ số</th><th class="ta-l">Mục tiêu</th><th class="ta-l">Cách thu</th><th class="ta-l">Sở hữu</th><th></th></tr></thead>
              <tbody>
                <tr v-for="d in dictRows" :key="d.c" :class="{ 'is-sel': dict.sel === d.c }" @click="selectDict(d.c)">
                  <td class="ta-l"><b>{{ d.c }}</b></td>
                  <td class="ta-l"><b>{{ d.n }}</b><small>{{ d.u }} · {{ d.f }}<template v-if="d.add"> · <span class="uc-kpi-rf__est">IT đề xuất</span></template></small></td>
                  <td class="ta-l">{{ d.tgt }}</td>
                  <td class="ta-l"><span :class="'uc-kpi-rf__mode m-' + d.now">{{ modeText[d.now] }}</span><span class="uc-kpi-rf__arrow">→</span><span :class="'uc-kpi-rf__mode m-' + d.goal">{{ modeText[d.goal] }}</span></td>
                  <td class="ta-l">{{ d.own }}</td>
                  <td>
                    <svg class="uc-kpi-rf__hb" viewBox="0 0 12 12"><circle cx="6" cy="6" r="5" class="hb-o" /><circle v-if="d.rd === 'good'" cx="6" cy="6" r="5" class="hb-f" /><path v-if="d.rd === 'part'" d="M6,1 A5,5 0 0 1 6,11 Z" class="hb-f" /></svg>
                  </td>
                </tr>
                <tr v-if="!dictRows.length"><td colspan="6" class="ta-l tx-muted">Không có chỉ số khớp.</td></tr>
              </tbody>
            </table>
          </div>
        </div>

        <div v-if="dictSel" class="uc-kpi-rf__visual uc-kpi-rf__span5 uc-kpi-rf__dictd">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">{{ dictSel.c }} · {{ dictSel.n }}</div>
            <span class="uc-kpi-rf__tag is-none">{{ dictStatusText[dictSel.st] }}</span>
          </div>
          <div v-if="dictSel.add" class="uc-kpi-rf__dictadd">IT đề xuất thêm, chưa có trong phương án 19/10</div>
          <dl class="uc-kpi-rf__dl">
            <template v-for="f in dictFields" :key="f.k">
              <dt>{{ f.t }}</dt>
              <dd :class="{ 'is-muted': dictSel[f.k] === '—' }">{{ dictSel[f.k] }}</dd>
            </template>
            <dt>Cách thu</dt>
            <dd><span :class="'uc-kpi-rf__mode m-' + dictSel.now">{{ modeText[dictSel.now] }}</span><span class="uc-kpi-rf__arrow">→</span><span :class="'uc-kpi-rf__mode m-' + dictSel.goal">{{ modeText[dictSel.goal] }}</span> <small class="tx-muted">hiện tại → mục tiêu</small></dd>
            <dt>Dùng ở tab</dt>
            <dd>{{ dictSel.used }}</dd>
            <dt>Đóng góp KPI chiến lược</dt>
            <dd><button v-if="dictSel.rfk" type="button" class="uc-kpi-rf__rflink1" @click="openRf(dictSel.rfk)">{{ dictSel.rfk }} · mở phiếu Tầng D</button><span v-else class="tx-muted">Chỉ số vận hành, chưa nối KPI chiến lược</span></dd>
          </dl>
          <div class="uc-kpi-rf__dictflow">
            <div v-for="(s, i) in dictFlow" :key="s.t" :class="['df-step', 'is-' + s.st]">
              <i>{{ i + 1 }}</i>
              <b>{{ s.t }}</b>
              <span>{{ s.who }}</span>
            </div>
          </div>
          <div v-if="dictSel.note" class="uc-kpi-rf__callout">{{ dictSel.note }}</div>
        </div>
      </div>
      <div class="uc-kpi-rf__src" style="padding-bottom: 8px">Bản nháp do IT soạn từ phương án ngày 19/10 và Phụ lục 10 của báo cáo tổng kết. Các mục ghi "IT đề xuất" là bổ sung để chỉ số đo được đúng, cần người sở hữu xác nhận. File CSV mở được bằng Excel để các bên góp ý.</div>
      </template>
    </div>

    <!-- ================= PAGE 10/11: TẦNG B, C (GIAI ĐOẠN SAU) ================= -->
    <div v-if="page === 10 || page === 11" class="uc-kpi-rf__page">
      <div class="uc-kpi-rf__lead">
        <div class="uc-kpi-rf__lead-k"><span>{{ tierInfo.k }}</span></div>
        <div class="uc-kpi-rf__lead-t">{{ tierInfo.lead }}</div>
      </div>
      <div class="uc-kpi-rf__grid">
        <div class="uc-kpi-rf__visual uc-kpi-rf__span7 uc-kpi-rf__empty">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Tầng này sẽ hiển thị</div>
            <div class="uc-kpi-rf__vnote">Chưa có dữ liệu</div>
          </div>
          <ul class="uc-kpi-rf__tierlist"><li v-for="x in tierInfo.show" :key="x">{{ x }}</li></ul>
        </div>
        <div class="uc-kpi-rf__visual uc-kpi-rf__span5">
          <div class="uc-kpi-rf__vhead">
            <div class="uc-kpi-rf__vtitle">Điều kiện trước khi dựng</div>
            <div class="uc-kpi-rf__vnote">Theo rà soát CSDL của chuyên gia KPI</div>
          </div>
          <ul class="uc-kpi-rf__tierlist is-pre"><li v-for="x in tierInfo.pre" :key="x">{{ x }}</li></ul>
          <div class="uc-kpi-rf__src">Lộ trình đề xuất: 0–2 tháng khóa định nghĩa, 2–4 tháng pilot, 4–6 tháng tích hợp và dashboard thử, 6–12 tháng mở rộng.</div>
        </div>
      </div>
    </div>

    <!-- Page tabs -->
    <div class="uc-kpi-rf__tabs">
      <div v-if="present" class="uc-kpi-rf__tabrow is-present">
        <span class="uc-kpi-rf__tabgrp-l">Trình chiếu</span>
        <button v-for="(n, i) in presentPages" :key="'pp' + n" type="button" :class="{ 'is-on': page === n }" @click="page = n"><span class="tb-l">{{ i + 1 }}. {{ pageOf(n).t }}</span><span class="tb-s">{{ i + 1 }}. {{ pageOf(n).s }}</span></button>
        <button type="button" @click="openImpact(boardWorst, 'siso')"><span class="tb-l">5. Vùng tác động (ước tính)</span><span class="tb-s">5. Tác động</span></button>
        <button type="button" class="is-exit" @click="togglePresent()">Thoát</button>
      </div>
      <div v-for="row in (present ? [] : [1, 2])" :key="'row' + row" class="uc-kpi-rf__tabrow">
        <div v-for="g in groupsOf(row)" :key="g.k" :class="['uc-kpi-rf__tabgrp', 'is-' + g.k]">
          <span class="uc-kpi-rf__tabgrp-l">{{ g.t }}</span>
          <button v-for="p in pagesOf(g.k)" :key="p.n" type="button" :class="{ 'is-on': page === p.n, 'is-later': g.later }" :title="p.t" @click="page = p.n"><span class="tb-l">{{ p.t }}</span><span class="tb-s">{{ p.s }}</span></button>
        </div>
      </div></div>
    </div>
  </div>
</template>

<script>
	export default {
		data: function () {
    return {
      page: 0,
      unit: 'ALL',
      kpiFilter: 'all',
      showNames: false,
      flowPeriod: 't9',
      flowPeriods: [{ k: 't8', t: 'Tháng 8' }, { k: 't9', t: 'Tháng 9' }, { k: 'cum', t: 'Lũy kế T8–T9' }],
      flowText: { tot: 'Khỏe mạnh', bu: 'Rò rỉ, đang bù bằng tuyển mới', thieu: 'Thiếu nguồn vào', xau: 'Báo động' },
      flowTag: { tot: 'good', bu: 'warn', thieu: 'warn', xau: 'bad' },
      quick: { unit: 'MNLK', vin: 3, vout: 7, months: 1 },
      simPreset: 'hien',
      sim: { start: 10, mode: 'cons', target: 0.95,
        lead: { PTLC: 0, MNBH: 0, MNLK: 0 }, conv: { PTLC: 0, MNBH: 0, MNLK: 0 },
        keep: { MNBH: 0, MNLK: 0, TH: 0, THCS: 0, THPT: 0 }, add: { MNBH: 0, MNLK: 0, TH: 0, THCS: 0, THPT: 0 },
        cost: { mkt: 0, keep: 0, add: 0 } },
      simPresets: [
        { k: 'hien', t: 'Dự báo nền' },
        { k: 'ke', t: 'Kế hoạch đề xuất' },
        { k: 'tv', t: 'Tham vọng' },
        { k: 'custom', t: 'Tùy chỉnh' }
      ],
      costItems: [
        { k: 'mkt', t: 'Tăng ngân sách tuyển sinh, marketing' },
        { k: 'keep', t: 'Chương trình giữ chân học sinh' },
        { k: 'add', t: 'Chiến dịch tuyển bổ sung, ưu đãi' }
      ],
      saved: [],
      printing: false,
      printedAt: '',
      impact: { open: false, type: 'rut', unit: 'MNLK', n: 5, reason: 5, month: 10, addN: 20, convUnit: 'MNBH', convDelta: 5, convMonths: 3, hover: '', showDetail: false },
      impactTypes: [
        { k: 'rut', t: 'Học sinh rời đi' },
        { k: 'siso', t: 'Tuyển thêm học sinh' },
        { k: 'conv', t: 'Thay đổi chuyển đổi' }
      ],
      classMax: { MNBH: 25, MNLK: 25, TH: 30, THCS: 35, THPT: 35 },
      failRoutes: {
        'Không liên lạc được (gọi 3 lần)': { o: 'TVTS + Marketing', a: 'Gọi lại trong 15 phút đầu; lọc lead kém chất lượng từ Facebook' },
        'Bé chưa đủ tuổi': { o: 'TVTS', a: 'Đưa vào danh sách nuôi dưỡng, hẹn lại khi đủ tuổi' },
        'Không đạt điều kiện tuyển sinh': { o: 'Ban Tuyển sinh', a: 'Rà tiêu chí, gợi ý cấp/lớp phù hợp' },
        'Không còn nhu cầu': { o: 'Marketing', a: 'Rà chất lượng nguồn lead' },
        'Chặn Facebook': { o: 'Marketing', a: 'Chuyển kênh liên hệ (Zalo, điện thoại)' },
        'Ngoài tuyến xe đưa đón': { o: 'Bán trú – Xe đưa rước', a: 'Đánh giá mở tuyến theo cụm địa chỉ' },
        'Phụ huynh tham khảo trước': { o: 'TVTS', a: 'Mời tham quan, trải nghiệm trong 7 ngày' },
        'Học phí cao': { o: 'Kế toán – Chính sách', a: 'Gói ưu đãi, chia kỳ thanh toán' }
      },
      failPtlc: [
        { k: 'Không liên lạc được (gọi 3 lần)', v: 11 },
        { k: 'Phụ huynh tham khảo trước', v: 3 }
      ],
      monthOptions: [
        { m: 10, t: 'Đầu tháng 10', r: 8 / 9, since: 3 },
        { m: 11, t: 'Đầu tháng 11', r: 7 / 9, since: 4 },
        { m: 12, t: 'Đầu tháng 12', r: 6 / 9, since: 5 },
        { m: 1, t: 'Đầu tháng 1', r: 5 / 9, since: 6 },
        { m: 2, t: 'Đầu tháng 2', r: 4 / 9, since: 7 },
        { m: 3, t: 'Đầu tháng 3', r: 3 / 9, since: 8 },
        { m: 4, t: 'Đầu tháng 4', r: 2 / 9, since: 9 },
        { m: 5, t: 'Đầu tháng 5', r: 1 / 9, since: 10 }
      ],
      reasonRoutes: [
        { k: 'Nơi ở / đưa đón', owner: 'Bán trú – Xe đưa rước', watch: 'Độ phủ tuyến xe; lead thất bại vì "ngoài tuyến xe"', act: 'Rà tuyến xe theo địa chỉ học sinh, đề xuất điểm đón mới', ctl: 'Trung bình' },
        { k: 'Kinh tế', owner: 'Kế toán – Chính sách học phí', watch: 'Nợ học phí; tỷ lệ dùng ưu đãi', act: 'Liên hệ phụ huynh trước khi rút, xem gói hỗ trợ học phí', ctl: 'Trung bình' },
        { k: 'Bệnh', owner: 'Y tế học đường', watch: 'Ca bệnh theo lớp; chuyên cần', act: 'Theo dõi sức khỏe, đề xuất bảo lưu thay vì rút', ctl: 'Trung bình' },
        { k: 'Không hài lòng', owner: 'Hiệu trưởng – Chuyên môn', watch: 'Hài lòng phụ huynh; khiếu nại; kết quả dự giờ', act: 'Gặp phụ huynh, xử lý phản ánh trong 48 giờ', ctl: 'Cao' },
        { k: 'Định cư & du học', owner: 'Tuyển sinh – Đối ngoại', watch: 'Nguyện vọng du học; đối tác', act: 'Ít kiểm soát được; ghi nhận để dự báo', ctl: 'Thấp' },
        { k: 'Chưa rõ lý do', owner: 'Hiệu trưởng (phải phân loại trước)', watch: '14/53 ca toàn hệ thống đang để "Khác"; lý do chưa tách theo đơn vị', act: 'Phỏng vấn rời trường, chọn lý do chuẩn rồi mới giao xử lý', ctl: 'Chưa rõ', unknown: true }
      ],
      srcText: { that: 'Dữ liệu thật', uoc: 'Ước tính', chua: 'Chưa có dữ liệu' },
      lifeAssume: {
        MNBH: { yrs: 2, p: 0.4, ny: 5, nhp: 49.6, nl: 'Tiểu học' },
        MNLK: { yrs: 2, p: 0.4, ny: 5, nhp: 49.6, nl: 'Tiểu học' },
        TH: { yrs: 2.5, p: 0.7, ny: 4, nhp: 61.7, nl: 'THCS' },
        THCS: { yrs: 2, p: 0.6, ny: 3, nhp: 63.6, nl: 'THPT' },
        THPT: { yrs: 1.5, p: 0, ny: 0, nhp: 0, nl: '' }
      },
      referral: { PTLC: 13 / 53, MNBH: 16 / 221, MNLK: null },
      remain: 8 / 9,
      mInc: 0.85,
      mAvgLong: 0.5,
      cacTarget: 13.5,
      rutTargetYear: 0.10,
      feed: { mn: 40, th: 70, thcs: 60 },
      map: { hover: '', flow: 'in', rec: { care: 30, kll: 5, age: 40, ref: 30, bus: 50, fee: 25 } },
      mapHp: 39.1,
      hpSource: { note: 'Học phí niêm yết 2026 trên website LHBS (chưa gồm bán trú, quy về năm theo hệ số cả năm của trường): MN 37,2 · TH 49,6 · THCS 61,7 · THPT 63,6 triệu. Khớp báo cáo thường niên 2024–25 (149,3 tỷ) trong khoảng 0,1%.' },
      mapFieldsLead: ['Năm sinh của trẻ', 'Phường/xã nơi ở', 'Trường đang học', 'Anh chị em đang học LHBS', 'Kênh nguồn (danh mục chuẩn)', 'Mã tư vấn viên'],
      mapFieldsOut: ['Trường chuyển đến', 'Lý do chính (bỏ mục "Khác")', 'Khả năng quay lại'],
      mapReady: [
        { q: 'Lead đến từ kênh nào', st: 'part', stt: 'Một phần', where: 'Excel TVTS, sheet 8 (tổng theo tháng)', miss: 'Theo từng lead, chiến dịch, chi phí kênh', owner: 'Marketing', cap: 'Phiếu lead' },
        { q: 'Lead rơi ở bước nào', st: 'part', stt: 'Một phần', where: 'Excel TVTS (lý do thất bại, chỉ Mầm non)', miss: 'Mốc thời gian từng bước; tách theo cơ sở', owner: 'Trưởng nhóm TVTS', cap: 'CRM tuyển sinh' },
        { q: 'Họ là ai', st: 'none', stt: 'Chưa có', where: '—', miss: 'Năm sinh trẻ, trường đang học, anh chị em ở LHBS', owner: 'TVTS', cap: 'Phiếu lead' },
        { q: 'Họ ở đâu', st: 'none', stt: 'Chưa có', where: 'Học sinh đang học có thể có địa chỉ trong ME / thu phí (cần kiểm tra); lead thì chưa', miss: 'Phường/xã, khoảng cách, trong tuyến xe hay không', owner: 'TVTS + Bán trú – Xe', cap: 'Phiếu lead, hồ sơ HS' },
        { q: 'Vì sao học sinh rút', st: 'part', stt: 'Một phần', where: 'Excel vận hành (tổng toàn hệ thống)', miss: 'Tách theo đơn vị; 14/53 ca để "Khác"', owner: 'Hiệu trưởng', cap: 'Phiếu rút hồ sơ' },
        { q: 'Học sinh rút đi đâu', st: 'none', stt: 'Chưa có', where: '—', miss: 'Trường chuyển đến, khả năng quay lại', owner: 'Hiệu trưởng', cap: 'Phiếu rút hồ sơ' },
        { q: 'Bao nhiêu em lên cấp trong LHBS', st: 'none', stt: 'Chưa có', where: 'Mầm non và Liên cấp dùng mã học sinh riêng', miss: 'Mã học sinh chung', owner: 'CNTT', cap: 'ME' },
        { q: 'Mỗi kênh tốn bao nhiêu', st: 'none', stt: 'Chưa có', where: 'Kế toán và Marketing, rời rạc', miss: 'Chi phí theo kênh, nên chưa tính được CAC', owner: 'Kế toán + Marketing', cap: 'Sổ chi phí marketing' }
      ],
      bm: { level: 'TH', hover: '' },
      bmLevels: [
        { k: 'MN', t: 'Mầm non', s: 'MN' },
        { k: 'TH', t: 'Tiểu học', s: 'TH' },
        { k: 'THCS', t: 'THCS', s: 'CS' },
        { k: 'THPT', t: 'THPT', s: 'PT' }
      ],
      bmSrcText: { cong: 'Công bố', tong: 'Tổng hợp web', gia: 'Giả định', that: 'Dữ liệu thật', none: 'Chưa công bố' },
      bmSchools: [
        { k: 'LHBS', t: 'LHBS · Song ngữ Lạc Hồng', short: 'LHBS', self: true, area: 'Trấn Biên (Biên Hòa) · Long Khánh', lv: ['MN', 'TH', 'THCS', 'THPT'], prog: 'Song ngữ, tiếng Anh Cambridge',
          fee: { MN: 37.2, TH: 49.6, THCS: 61.7, THPT: 63.6 }, feeSrc: 'cong', feeNote: 'lhbs.edu.vn, học phí niêm yết 2026: TH 5,1–5,6 · THCS 6,6 · THPT 6,8 · MN 3,71–4,28 triệu/tháng, quy về năm theo hệ số cả năm của trường, chưa gồm bán trú. Khớp BC thường niên 2024–25.', q: 70, vs: '—' },
        { k: 'IPS', t: 'IPS Đồng Nai (Thái Bình Dương)', short: 'IPS', area: 'Hưng Đạo Vương, Trấn Biên · hệ thống IGC', lv: ['TH', 'THCS', 'THPT'], prog: 'ESL, ESL+, Cambridge (CAIE)',
          fee: { TH: 89.6, THCS: 103.2, THPT: 117.7 }, feeSrc: 'cong', feeNote: 'ips.igcschool.edu.vn, biểu phí 2026–27, hệ ESL: 116,9 / 130,5 / 145,0 triệu gồm bán trú, đã trừ bán trú 3,036 triệu × 9 tháng. Hệ CAIE 156–243 triệu.', hs: { TH: 500, THCS: 350, THPT: 250 }, q: 78, vs: 'Liên cấp' },
        { k: 'LQD', t: 'Lê Quý Đôn – Quyết Thắng', short: 'Lê Quý Đôn', area: '154/20 Hưng Đạo Vương, Trấn Biên · hệ thống IGC', lv: ['TH', 'THCS', 'THPT'], prog: 'Chương trình Bộ, tư thục',
          fee: { TH: 41.0, THCS: 39.0, THPT: 40.8 }, feeSrc: 'cong', feeNote: 'lqdqt.igcschool.edu.vn, biểu phí 2026–27: 52–54,5 triệu gồm bán trú; THPT không bán trú 40,3–41,1 triệu.', hs: { TH: 700, THCS: 600, THPT: 500 }, q: 72, vs: 'Liên cấp' },
        { k: 'ACH', t: 'Song ngữ Á Châu (ABC EDU)', short: 'Á Châu', area: '154/22 Hưng Đạo Vương, Trấn Biên', lv: ['TH', 'THCS', 'THPT'], prog: 'Song ngữ, Cambridge; lớp 10 song bằng Việt – Úc',
          fee: { TH: 61.9, THCS: 63.7, THPT: 65.5 }, feeSrc: 'cong', feeNote: 'abcedu.vn, học phí 2026–27: 6,88 / 7,08 / 7,28 triệu/tháng, quy đổi × 9 tháng; bán trú 1,32 triệu/tháng.', hs: { TH: 500, THCS: 400, THPT: 300 }, q: 66, vs: 'Liên cấp' },
        { k: 'BTX', t: 'Bùi Thị Xuân Biên Hòa', short: 'Bùi Thị Xuân', area: '1359 Nguyễn Ái Quốc, Tam Hiệp · thành lập 1999', lv: ['TH', 'THCS', 'THPT'], prog: 'Hệ phổ thông, chất lượng cao, song ngữ',
          fee: { TH: 44.5, THCS: 27.2, THPT: 33.9 }, feeSrc: 'cong', feeNote: 'buithixuan.edu.vn, học phí 2026–27: TH hệ song ngữ 4,8–5,1 triệu/tháng; THCS–THPT hệ chất lượng cao 3,0–4,5 triệu/tháng; quy đổi × 9 tháng, chưa gồm bán trú 1,8–2,8 triệu/tháng.', hs: { TH: 1900, THCS: 1600, THPT: 1200 }, hsSrc: 'tong', hsNote: 'mytour.vn: khoảng 4.700 HS, chia theo cấp là giả định', q: 70, vs: 'Liên cấp' },
        { k: 'INS', t: 'INschool Long Khánh', short: 'INschool', area: '262 Nguyễn Tri Phương, Long Khánh · Liên Kết Quốc Tế', lv: ['MN', 'TH', 'THCS', 'THPT'], prog: 'Song ngữ, liên kết quốc tế',
          fee: { TH: 64.2, THCS: 77.3, THPT: 88.5 }, feeSrc: 'cong', feeNote: 'inschool.edu.vn, biểu phí 2025–26 (giữ nguyên 2026–27), tính 11 tháng; bán trú 1,7 triệu/tháng. Mầm non chưa có biểu phí.', hs: { TH: 386, THCS: 288, THPT: 85 }, hsSrc: 'cong', hsNote: 'Báo cáo thường niên 2024–25: 32 lớp, 766 HS', q: 65, vs: 'MN Long Khánh' },
        { k: 'SNA', t: 'SNA Marianapolis Biên Hòa', short: 'SNA', area: 'Đường 30/4, Biên Hòa', lv: ['TH', 'THCS', 'THPT'], prog: 'Quốc tế Mỹ, IB',
          fee: { TH: 340, THCS: 368, THPT: 413 }, feeSrc: 'tong', feeNote: 'international-schools-database (2026/27), chưa chắc đúng cơ sở Biên Hòa. Số 515–843 triệu trước đây là của cơ sở Nam Sài Gòn.', hs: { TH: 150, THCS: 120, THPT: 100 }, q: 85, vs: 'Phân khúc cao cấp (tham chiếu trần)' },
        { k: 'ACN', t: 'Mầm non Song ngữ Á Châu – N2', short: 'MN Á Châu', area: '103 Đường N2, Trấn Biên · ABC EDU', lv: ['MN'], prog: 'Song ngữ',
          fee: { MN: 57.6 }, feeSrc: 'tong', feeNote: 'kiddi.vn: trên 4,8 triệu/tháng × 12, chưa kiểm chứng trên website trường', hs: { MN: 200 }, q: 62, vs: 'MN Biên Hòa' },
        { k: 'BHS', t: 'Biên Hòa School (BHS)', short: 'BHS', area: '206 Nguyễn Khuyến, Trảng Dài · lập 2025 · hệ sinh thái BHS & DNTU', lv: ['TH', 'THCS', 'THPT'], prog: 'Chương trình Bộ + chương trình BHS; tiếng Anh tăng cường, STEAM',
          fee: {}, feeSrc: 'none', feeNote: 'bhs.edu.vn chưa công bố học phí, chưa có mục công khai; chỉ tiêu 2026–27: 3 lớp 1, 1 lớp 6, 10 lớp 10.', hs: { TH: 400, THCS: 500, THPT: 800 }, hsNote: 'quy mô suy ra từ chỉ tiêu, là giả định', q: 64, vs: 'Liên cấp, mạnh ở THPT (10 lớp 10)' },
        { k: 'WIS', t: 'Mầm non Worldkids – WIS', short: 'Worldkids', area: 'Chưa xác minh có cơ sở Biên Hòa (nguồn chỉ thấy TP.HCM)', lv: ['MN'], prog: 'Song ngữ, khung IEYC (Anh)',
          fee: {}, feeSrc: 'none', feeNote: 'Chưa xác minh. Số 7,62 triệu/tháng trên kiddi.vn chưa kiểm chứng.', hs: { MN: 250 }, q: 75, vs: 'MN Biên Hòa' },
        { k: 'BSC', t: 'B.School (Bcons)', short: 'B.School', area: 'Chưa xác minh cơ sở Biên Hòa (web chỉ thấy Dĩ An)', lv: ['TH', 'THCS'], prog: 'Liên cấp, định hướng quốc tế',
          fee: {}, feeSrc: 'none', feeNote: 'Chưa xác minh, chưa thấy biểu phí.', hs: { TH: 300, THCS: 200 }, q: 65, vs: 'Liên cấp' },
        { k: 'SKH', t: 'Song ngữ Sao Khuê', short: 'Sao Khuê', area: 'Biên Hòa · không tìm thấy website', lv: ['TH', 'THCS'], prog: 'Song ngữ',
          fee: {}, feeSrc: 'none', feeNote: 'Không tìm thấy website, chưa xác minh còn hoạt động.', hs: { TH: 300, THCS: 200 }, q: 60, vs: 'Liên cấp' }
      ],
      bmLossRaw: [
        { k: 'cong', t: 'Trường công lập gần nhà', s: 0.28 },
        { k: 'ACH', t: 'Song ngữ Á Châu', s: 0.12 },
        { k: 'LQD', t: 'Lê Quý Đôn – Quyết Thắng', s: 0.10 },
        { k: 'BTX', t: 'Bùi Thị Xuân', s: 0.08 },
        { k: 'IPS', t: 'IPS Đồng Nai', s: 0.07 },
        { k: 'INS', t: 'INschool Long Khánh', s: 0.07 },
        { k: 'BHS', t: 'Biên Hòa School (BHS)', s: 0.05 },
        { k: 'nghi', t: 'Nghỉ ở nhà / bảo lưu', s: 0.10 },
        { k: 'tinh', t: 'Tỉnh khác / nước ngoài', s: 0.05 },
        { k: 'khac', t: 'Khác', s: 0.08 }
      ],
      bmPlan: [
        { t: 'Phiếu rút hồ sơ, lead rơi', what: 'Trường chuyển đến, trường đã chọn thay LHBS', who: 'Hiệu trưởng, tư vấn viên', when: 'liên tục' },
        { t: 'Website, fanpage đối thủ', what: 'Biểu phí, chương trình, ưu đãi', who: 'Marketing', when: 'đầu mùa tuyển sinh' },
        { t: 'Sở GD&ĐT Đồng Nai', what: 'Số HS theo trường, điểm thi vào 10, tốt nghiệp', who: 'M&E', when: 'hằng năm' },
        { t: 'Meta Ad Library, Google Maps', what: 'Quảng cáo đang chạy, điểm đánh giá', who: 'Marketing', when: 'hằng quý' },
        { t: 'Đóng vai phụ huynh hỏi tư vấn', what: 'Tốc độ phản hồi, cách tư vấn, ưu đãi', who: 'Marketing', when: '2 lần/năm' }
      ],
      board: { more: false },
      fold: { qm: false, ts: false },
      covText: { good: 'Có', part: 'Một phần', none: 'Chưa có' },
      present: false,
      presentPages: [0, 6, 3, 7],
      prevYear: { rut: 0.07, leads: 1840, nh: 259, conv: 259 / 1840 },
      rfv: { act: false, tab: 'base' },
      boardStText: { good: 'Đúng nhịp', warn: 'Cần theo dõi', bad: 'Dưới đích' },
      dict: { grp: 'ALL', q: '', sel: 'TS-01', tier: 'D', selD: 'KPI 1' },
      rfDict: [{"c": "KPI 1", "n": "Tuyển sinh hàng năm đạt 100% công suất của trường", "def": "Chỉ số KPI này theo dõi mức độ thành công của LHBS trong việc lấp đầy tất cả các chỗ học ở mọi khối lớp, mỗi năm học – từ mầm non đến trung học phổ thông. - Nó phản ánh hiệu quả của qui trình tuyển sinh, sức mạnh của hoạt động marketing và sự hiện diện thương hiệu, cũng như sự hài lòng và trung thành của các gia đình hiện tại khi họ giới thiệu LHBS cho người khác. - Nó đo lường không chỉ khả năng thu hút học sinh mới mà còn cả việc duy trì học sinh hiện tại thông qua chất lượng giảng dạy xuất sắc, sự quan tâm đến học sinh, các chương trình ngoại khóa và sự gắn kết với phụ huynh. - Đây là “thước đo” cho thấy trải nghiệm toàn diện tại LHBS đáp ứng nhu cầu và kì vọng của các gia đình ở Đồng Nai và xa hơn đến mức nào.", "why": "Việc đạt và duy trì 100% chỉ tiêu tuyển sinh không chỉ là một mục tiêu về con số – mà còn là dấu hiệu cho thấy: - Danh tiếng của chúng ta đang phát triển mạnh mẽ – các gia đình tin tưởng LHBS là lựa chọn tốt nhất cho nền giáo dục song ngữ, sẵn sàng cho tương lai. - Cộng đồng của chúng ta năng động – một ngôi trường đầy đủ học sinh mang đến những giờ thảo luận phong phú hơn, nhiều tài năng đa dạng hơn, và nhiều cơ hội hợp tác hơn cho học sinh. - Nền tảng tài chính của chúng ta vững chắc – tuyển sinh ổn định tạo nguồn lực để đầu tư vào đội ngũ giáo viên, chương trình và cơ sở vật chất tốt nhất. - Sứ mệnh của chúng ta đang được thực thi – khi mọi chỗ học đều được lấp đầy và học sinh gắn bó qua từng năm, điều đó có nghĩa chúng ta đang thực hiện đúng cam kết về chất lượng, sự chăm sóc và sự phát triển. Đối với tất cả mọi người tại LHBS, việc đạt 100% chỉ tiêu tuyển sinh không chỉ là một mục tiêu của phòng tuyển sinh – mà là bằng chứng tập thể cho thấy nỗ lực của chúng ta trong từng lớp học, từng văn phòng và từng hoạt động đã truyền cảm hứng để các gia đình chọn và gắn bó cùng LHBS.", "asp": "Duy trì 100% công suất tuyển sinh qua từng năm, khẳng định LHBS là lựa chọn hàng đầu cho giáo dục song ngữ tại Đồng Nai.", "unit": "% (phần trăm)", "method": "[Tỉ lệ học sinh theo học so với công suất ] = ([Tổng học sinh mới nhập học] + [Tổng HS cũ theo đang theo học] / [Số lượng HS theo tổng công suất HS trường])*100", "split": "1. Cấp học (Mầm non, Tiểu học, THCS, THPT) 2. Khối lớp 3. Năm học", "collect": "Xác định công suất tối đa (dựa trên số phòng học khả dụng × sĩ số chuẩn/lớp). - Tổng hợp chỉ tiêu tuyển sinh mới từng cấp học do Phòng Tuyển sinh ban hành đầu năm. - Ghi nhận số HS mới nhập học từ hồ sơ nhập học chính thức. - Ghi nhận số HS cũ tiếp tục học từ sổ theo dõi sĩ số lớp và SIS. - Đối chiếu, xác nhận số liệu với giáo viên chủ nhiệm và phòng Đào tạo.", "src": "Phòng Tuyển sinh – Đào tạo, Hồ sơ tuyển sinh, hệ thống quản lí học sinh (SIS), sổ đầu bài/lớp, báo cáo sĩ số từ giáo viên chủ nhiệm, kế hoạch tuyển sinh đã phê duyệt.", "freq": "3 lần/năm - 15/8 (trước khi khai giảng, để đối chiếu chỉ tiêu – thực tế). - 31/12 (kết thúc HK1, cập nhật sĩ số chính thức). - 31/5 (kết thúc HK2, báo cáo tổng hợp năm học).", "owner": "Trưởng/Phó phòng Tuyển sinh – Đào tạo (chủ trì); phối hợp với Giáo viên chủ nhiệm, Phòng Hành chính.", "store": "Dữ liệu điện tử: SIS + file Excel tổng hợp lưu tại thư mục chung “KPI_Enrollment”. - Dữ liệu bản cứng: Hồ sơ tuyển sinh, sổ sĩ số lớp, báo cáo tuyển sinh tại Phòng Tuyển sinh – Đào tạo.", "analyze": "So sánh tỉ lệ HS thực tế/công suất qua từng năm học. - Phân tích mức độ hoàn thành chỉ tiêu tuyển sinh (% HS mới nhập học/chỉ tiêu). - Đối chiếu theo cấp học, khối lớp để nhận diện điểm mạnh/yếu. - Xem xét xu hướng tăng/giảm sĩ số và tỉ lệ rút lui/học sinh chuyển trường.", "present": "Bảng tổng hợp tỉ lệ % và số lượng HS theo từng cấp học, khối lớp. - Biểu đồ cột/đường (so sánh công suất, chỉ tiêu và thực tế). - Dashboard trực quan trong SIS hoặc file báo cáo KPI.", "verify": "Chuyên viên M&E – rà soát tính chính xác của số liệu và công thức tính. - Ban Giám hiệu – xác minh và phê duyệt kết quả cuối cùng.", "report": "Báo cáo định kì trong giao ban Ban Giám hiệu (3 lần/năm). - Báo cáo tóm tắt KPI gửi HĐQT hàng quý/năm. - Báo cáo kết quả cuối năm trong họp chiến lược/đánh giá tổng thể.", "pts": [{"n": "1", "name": "Số lượng phòng học khả dụng", "desc": "Tổng số phòng học có thể được sử dụng cho các hoạt động giảng dạy và học tập trong một khoảng thời gian nhất định, sau khi loại trừ các phòng đang bảo trì, sửa chữa hoặc bị sử dụng cho mục đích khác."}, {"n": "2", "name": "Số lượng HS theo tổng công suất HS trường", "desc": "Tổng số học sinh tối đa mà trường có thể tiếp nhận, tính theo số phòng học khả dụng và sĩ số chuẩn mỗi lớp."}, {"n": "3", "name": "Số lượng HS tuyển sinh mới theo chỉ tiêu", "desc": "Chỉ tiêu học sinh mới được đặt ra cho từng năm học theo kế hoạch tuyển sinh."}, {"n": "4", "name": "Tổng học sinh mới nhập học", "desc": "Số học sinh mới thực tế đã nhập học trong năm học đó."}, {"n": "5", "name": "Tổng HS cũ theo đang theo học", "desc": "Số học sinh tiếp tục học từ các năm trước, không bao gồm học sinh mới nhập học."}, {"n": "6", "name": "Tỉ lệ học sinh theo học so với công suất", "desc": "(([4]+[5])/[2])*100 Tỉ lệ phần trăm tổng số học sinh (mới + cũ) so với công suất tối đa của trường."}, {"n": "7", "name": "Tỉ lệ % hoàn thành chỉ tiêu tuyển sinh", "desc": "([4]/[3])*100 Tỉ lệ phần trăm học sinh mới nhập học so với chỉ tiêu tuyển sinh đặt ra."}], "cut": ["15/8", "31/12", "31/5"], "cutNote": "", "review": ["Bảng KPI ghi \"100% công suất\", trang đầu mối ghi \"100% chỉ tiêu tuyển sinh\": hai mẫu số khác nhau.", "Dòng phương pháp tính thiếu ngoặc; đúng là (([4]+[5])/[2])×100 như điểm dữ liệu [6]."], "out": "HT"}, {"c": "KPI 2", "n": "Tăng Tỉ lệ học sinh trúng tuyển vào các trường đại học hàng đầu trong nước và quốc tế thông qua lộ trình học tập cá nhân hóa", "def": "Chỉ số KPI này theo dõi mức độ hiệu quả của LHBS trong việc chuẩn bị và hỗ trợ học sinh tốt nghiệp trúng tuyển vào các trường đại học chất lượng cao ở Việt Nam và trên thế giới – bao gồm cả những trường có tiêu chuẩn tuyển sinh cạnh tranh, chương trình chuyên biệt hoặc danh tiếng toàn cầu. - Nó đo lường tác động của các lộ trình học tập cá nhân hóa, trong đó chương trình học, phát triển kĩ năng và hồ sơ hoạt động ngoại khóa của từng học sinh được thiết kế phù hợp với mục tiêu tương lai của các em. - Nó phản ánh sức mạnh của chương trình giảng dạy, chất lượng giảng dạy, công tác tư vấn hướng nghiệp và mạng lưới hợp tác với các trường đại học. - Nó cũng thể hiện năng lực của chúng ta trong việc hướng dẫn học sinh qua các qui trình ứng tuyển, cơ hội học bổng và chuẩn bị phỏng vấn, giúp các em tự tin cạnh tranh ở bậc học tiếp theo.", "why": "Thành công trong việc học sinh trúng tuyển đại học không chỉ là một con số thống kê – mà còn là tín hiệu mạnh mẽ gửi đến học sinh, phụ huynh và cộng đồng rằng: - Học sinh tốt nghiệp của chúng ta sẵn sàng bước ra thế giới – các em rời LHBS với tri thức, kĩ năng và sự tự tin để tỏa sáng trong những môi trường học thuật đầy thử thách. - Việc giảng dạy của chúng ta có tác động và tính thực tiễn – những gì diễn ra trong lớp học tại LHBS được kết nối trực tiếp với cơ hội thật sự sau khi tốt nghiệp. - Sự định hướng của chúng ta mang tính cá nhân và hiệu quả – mọi ước mơ của học sinh đều được lắng nghe, hỗ trợ và chuẩn bị chiến lược. - Danh tiếng của chúng ta ngày càng lớn mạnh – việc học sinh liên tục trúng tuyển vào các trường đại học hàng đầu củng cố vị thế LHBS như một con đường đáng tin cậy dẫn đến thành công học thuật và nghề nghiệp. Đối với tất cả mọi người tại LHBS – từ giáo viên bộ môn, cố vấn hướng nghiệp cho đến người phụ trách hoạt động – KPI này là bằng chứng sống động cho thấy công việc tập thể của chúng ta đang kiến tạo cơ hội thay đổi cuộc đời cho học sinh. Mỗi bài học, mỗi dự án được hướng dẫn, mỗi kĩ năng được nuôi dưỡng đều đưa các em đến gần hơn với ngôi trường đại học và tương lai mà các em khao khát.", "asp": "Không ngừng cải thiện tỉ lệ trúng tuyển đại học trong nước và quốc tế qua từng năm, xây dựng danh tiếng vững chắc về thành tích đầu ra ưu tú của học sinh.", "unit": "% (phần trăm)", "method": "[Tỉ lệ HS lớp 12 trúng tuyển ĐH (công lập, tư thục, quốc tế)] = (([Tổng số học sinh lớp 12 tốt nghiệp vào đại học công lập] + [Tổng số học sinh lớp 12 tốt nghiệp vào đại học ngoài công lập (tư thục)] + [Tổng số học sinh nhập học vào các trường nước ngoài (du học)]) / [Tổng số học sinh 12 tính theo năm học])*100", "split": "1. Năm học 2. Giới tính 3. Phân loại trường đại học (công lập trong nước, tư thục trong nước, trường quốc tế trong nước, trường quốc tế nước ngoài)", "collect": "Tổng hợp danh sách HS lớp 12 tốt nghiệp từ Phòng Giáo vụ. - Thu thập giấy báo trúng tuyển từ học sinh/ phụ huynh (bản sao hoặc bản scan). - Xác nhận kết quả trúng tuyển qua hệ thống công khai của các trường ĐH (nếu có). - Ghi nhận kết quả học bổng (nếu có) qua giấy chứng nhận hoặc email xác nhận của trường ĐH. - Đối chiếu và cập nhật dữ liệu vào biểu mẫu KPI hàng năm.", "src": "Hồ sơ học sinh (Phòng Giáo vụ, Văn phòng Trường THPT). - Giấy báo trúng tuyển đại học, giấy xác nhận học bổng. - Cơ sở dữ liệu tuyển sinh công khai từ các trường đại học trong và ngoài nước. - Phụ huynh và học sinh cung cấp thông tin bổ sung.", "freq": "1 lần/năm, ngay sau khi có kết quả tuyển sinh đại học chính thức (tháng 8–9 hằng năm). - hạn chót 30/9 hàng năm.", "owner": "Trưởng phòng Đào tạo THPT – chịu trách nhiệm tổng hợp danh sách và đối chiếu thông tin. Cán bộ Hướng nghiệp & Tư vấn Đại học – hỗ trợ xác minh thông tin và theo dõi học bổng.", "store": "Lưu trữ bản cứng tại Phòng Giáo vụ. - Lưu trữ bản mềm (scan) trên hệ thống quản lí dữ liệu nội bộ (Google Drive/SharePoint/Phần mềm SIS). - Đặt quiền truy cập cho Ban Giám hiệu và phòng M&E.", "analyze": "Tính tỉ lệ theo công thức. - Phân tích riêng tỉ lệ công lập – tư thục – quốc tế để so sánh theo năm. - Ghi chú thêm số HS nhận học bổng và theo dõi xu hướng tăng/giảm hằng năm.", "present": "Bảng biểu (theo năm học, theo loại trường ĐH). - Biểu đồ cột so sánh kết quả qua các năm. - Infographic ngắn gọn (nếu trình bày cho phụ huynh/Board).", "verify": "Chuyên viên M&E – rà soát tính chính xác của số liệu và công thức tính. - Ban Giám hiệu – xác minh và phê duyệt kết quả cuối cùng.", "report": "Báo cáo định kì hằng năm trong Báo cáo Kết quả Chiến lược (Results Framework Report). - Tóm tắt kết quả trong Bản tin Nội bộ và Báo cáo cho Hội đồng Chiến lược. - Cập nhật lên Dashboard KPI để theo dõi xu hướng nhiều năm.", "pts": [{"n": "1", "name": "Tổng số học sinh 12", "desc": "Tổng số học sinh 12 theo học tại trường trong từng năm học."}, {"n": "2", "name": "Tổng số HS 12 tốt nghiệp", "desc": "Tổng số học sinh lớp 12 tốt nghiệp trong từng năm học."}, {"n": "3", "name": "Số HS lớp 12 trúng tuyển ĐH công lập trong nước", "desc": "Số học sinh được nhận vào các trường đại học công lập hàng đầu tại Việt Nam."}, {"n": "4", "name": "Số HS lớp 12 trúng tuyển ĐH tư thục trong nước", "desc": "Số học sinh được nhận vào các trường đại học tư thục tại Việt Nam và trường đại học quốc tế có chi nhánh tại Việt Nam."}, {"n": "5", "name": "Số HS lớp 12 trúng tuyển ĐH quốc tế (du học)", "desc": "Số học sinh được nhận vào các trường đại học ngoài nước (du học)/top ranking (dựa trên bảng xếp hạng hoặc danh sách xác định trước)."}, {"n": "6", "name": "Tổng số HS lớp 12 trúng tuyển ĐH (công lập, tư thục, quốc tế)", "desc": "[3]+[4]+[5] Tổng số học sinh lớp 12 được nhận vào các trường đại học trong và ngoài nước, bao gồm công lập, tư thục và quốc tế."}, {"n": "7", "name": "Số HS nhận học bổng ĐH", "desc": "Số học sinh lớp 12 nhận học bổng khi trúng tuyển."}, {"n": "8", "name": "Tỉ lệ học sinh tốt nghiệp hằng năm", "desc": "([2]/[1])*100 Tỉ lệ % học sinh lớp 12 hoàn thành chương trình THPT trên tổng số học sinh lớp 12 trong năm học."}, {"n": "9", "name": "Tỉ lệ HS lớp 12 trúng tuyển ĐH (công lập, tư thục, quốc tế)", "desc": "([6]/[1])*100 Tỉ lệ % học sinh lớp 12 được nhận vào các trường đại học công lập, tư thục và quốc tế so với tổng số học sinh lớp 12 trong năm học."}, {"n": "10", "name": "Tỉ lệ học sinh trúng tuyển ĐH nhận học bổng", "desc": "([7]/[6])*100 Tỉ lệ % học sinh lớp 12 trúng tuyển đại học đồng thời nhận học bổng từ các trường so với tổng số học sinh trúng tuyển ĐH."}], "cut": ["30/9"], "cutNote": "", "review": [], "out": "HT"}, {"c": "KPI 3", "n": "Duy trì tỉ lệ học sinh rút khỏi trường dưới 10% tổng số học sinh vào đầu năm học", "def": "Chỉ số KPI này theo dõi mức độ thành công của LHBS trong việc giữ chân học sinh theo từng năm học, đảm bảo các em tiếp tục hành trình học tập cùng nhà trường thay vì chuyển sang trường khác. - Nó phản ánh chất lượng trải nghiệm học tập toàn diện – từ chương trình học, chất lượng giảng dạy đến các hoạt động ngoại khóa, sự chăm sóc học sinh và cơ sở vật chất của trường. - Nó đo lường mức độ tin tưởng và hài lòng của phụ huynh đối với văn hóa nhà trường, cách thức giao tiếp, cũng như cam kết trong việc nuôi dưỡng sự phát triển của con em họ. - Nó cũng là tín hiệu về sự ổn định của toàn cộng đồng LHBS, cho thấy học sinh và phụ huynh lựa chọn gắn bó vì họ cảm thấy được trân trọng, hỗ trợ và tin tưởng vào cam kết của nhà trường. Lưu ý: Mặc dù KPI này được đo lường ở cấp độ toàn trường, LHBS sẽ phân tách dữ liệu theo các giai đoạn chuyển cấp (ví dụ: từ lớp 9 → lớp 10) để xác định và xử lí các điểm rủi ro chính trong việc mất học sinh. Các lí do rút học cũng sẽ được theo dõi để phân biệt yếu tố bất khả kháng (như gia đình chuyển nơi ở) với việc chuyển trường do cạnh tranh, đồng thời “học sinh chuyển đến” cũng sẽ được thống kê nhằm cung cấp bức tranh tổng thể về sự ổn định và tăng trưởng tuyển sinh, đặc biệt khi các cơ sở mầm non và trung học mới đi vào hoạt động.", "why": "Tỉ lệ học sinh rút học thấp không chỉ là một chỉ số về khả năng duy trì – mà còn là minh chứng mạnh mẽ cho việc LHBS đang thực hiện đúng sứ mệnh của mình: - Phụ huynh tin tưởng vào chúng ta – họ nhìn thấy giá trị trong các chương trình và tin cậy LHBS đồng hành cùng con em họ qua từng năm học. - Cộng đồng vững mạnh và gắn kết – khi học sinh cùng nhau trưởng thành trong nhiều năm, tình bạn được bồi đắp, sự hợp tác được nâng cao và tinh thần trường học phát triển mạnh mẽ. - Cho phép lập kế hoạch và đầu tư dài hạn – một cộng đồng học sinh ổn định giúp chúng ta tập trung nguồn lực để nâng cao chất lượng thay vì phải lấp đầy những chỗ trống. - Phản ánh sự xuất sắc ở mọi khía cạnh của trường – bởi vì việc giữ chân học sinh không chỉ phụ thuộc vào học thuật, mà còn vào cách chúng ta chào đón gia đình mới, giải quiết vấn đề, chăm sóc sức khỏe tinh thần – thể chất cho học sinh và giao tiếp với phụ huynh. Đối với tất cả mọi người tại LHBS, việc duy trì tỉ lệ rút học thấp không chỉ là một mục tiêu hành chính – mà là một thành quả chung, cho thấy học sinh muốn tiếp tục gắn bó, phát triển và tốt nghiệp cùng chúng ta. Mỗi bài học truyền cảm hứng, mỗi sự quan tâm, mỗi trải nghiệm tích cực đều là lí do khiến một gia đình tiếp tục chọn LHBS cho năm học tiếp theo.", "asp": "Duy trì tỉ lệ học sinh rút học hằng năm ở mức thấp hơn nhiều so với 10%, đồng thời đảm bảo sự ổn định ở các giai đoạn chuyển cấp quan trọng (ví dụ: lớp 9 → lớp 10) và theo dõi tình hình chuyển đến/ra để có bức tranh toàn diện về sức khỏe tuyển sinh.", "unit": "% (phần trăm)", "method": "[Tỉ lệ % thay đổi qui mô học sinh ròng trong năm học] = (([HS đầu năm] – [HS rút học] + [HS chuyển đến]) / [HS đầu năm])*100", "split": "1. Năm học 2. Khối lớp 3. Phân loại lí do rút Thống kê lí do học sinh rời trường: - Chuyển nơi ở / định cư - Môi trường / chương trình không phù hợp - Du học quốc tế - lí do tài chính - lí do sức khỏe - lí do cá nhân/khác 4. Thời điểm rút tính theo tháng 5. Nơi chuyển đi", "collect": "Tổng hợp danh sách HS đầu năm từ hệ thống quản lí tuyển sinh & nhập học (SIS/Phòng Đào tạo). - Theo dõi biến động HS (rút học/chuyển đến) qua sổ theo dõi lớp, báo cáo GVCN, và quiết định chính thức từ Phòng Đào tạo. - Phân loại lí do rút học thông qua biên bản làm việc với phụ huynh/học sinh. - Tổng hợp dữ liệu và đối chiếu giữa Phòng Đào tạo và Phòng Tài chính – Kế toán (xác nhận thôi học).", "src": "Hệ thống SIS / phần mềm quản lí học sinh. - Báo cáo GVCN, Phòng Đào tạo, Phòng Tài chính – Kế toán. - Biên bản làm việc với phụ huynh/học sinh.", "freq": "2 lần/năm: (i) Cuối học kì 1 - hạn chót 31/12, (ii) Cuối năm học (tổng hợp số HS rút học, chuyển đến) - hạn chót 31/7. - Báo cáo hàng quý trường hợp rút học phát sinh.", "owner": "Trưởng phòng Đào tạo (chịu trách nhiệm chính). - GVCN các lớp (cung cấp dữ liệu ban đầu). - Nhân viên Phòng Tài chính – Kế toán (đối chiếu học phí để xác nhận tình trạng thôi học).", "store": "Lưu trên hệ thống SIS / Google Drive nội bộ của Phòng Đào tạo. - Biên bản và hồ sơ rút học lưu bản cứng tại văn phòng trường.", "analyze": "Tính tỉ lệ rút học toàn trường. - Tính tỉ lệ rút học theo năm chuyển cấp. - Phân tích nguyên nhân: thống kê và phân loại lí do rút học theo nhóm. - Tính biến động ròng.", "present": "Biểu đồ cột: tỉ lệ rút học toàn trường qua các năm. - Biểu đồ đường: xu hướng rút học theo năm chuyển cấp. - Bảng phân loại lí do rút học (phần trăm theo từng nguyên nhân).", "verify": "Chuyên viên M&E – rà soát tính chính xác của số liệu và công thức tính. - Ban Giám hiệu – xác minh và phê duyệt kết quả cuối cùng.", "report": "Báo cáo định kì 2 lần/năm (giữa năm và cuối năm học) gửi Ban Giám hiệu và Hội đồng Quản trị. - Báo cáo tóm tắt trong Dashboard KPI toàn trường (cập nhật hằng tháng). - Báo cáo chi tiết phân tích nguyên nhân rút học dùng trong các buổi họp quản lí & chiến lược tuyển sinh.", "pts": [{"n": "1", "name": "Tổng số HS đầu năm học", "desc": "Tổng số học sinh ghi danh chính thức tại thời điểm bắt đầu năm học (1/8)."}, {"n": "2", "name": "Tổng số HS rút học giữa năm", "desc": "Tổng số học sinh rời trường trong năm học (bất kì thời điểm nào, tính đến 31/7)."}, {"n": "3", "name": "Tổng số HS đầu năm học ở các năm chuyển cấp", "desc": "Tổng số học sinh ở các năm chuyển cấp quan trọng (VD: cuối lớp Lá ở Mầm non, cuối lớp 5 ở Tiểu học, cuối lớp 9 ở THCS) ghi danh chính thức tại thời điểm bắt đầu năm học."}, {"n": "4", "name": "Số HS rút học ở các năm chuyển cấp", "desc": "Số học sinh rời trường tại các điểm chuyển cấp quan trọng (VD: cuối lớp Lá ở Mầm non, cuối lớp 5 ở Tiểu học, cuối lớp 9 ở THCS)."}, {"n": "5", "name": "Số HS chuyển đến (transfer in) chung toàn trường", "desc": "Tổng số học sinh nhập học bổ sung từ trường khác trong năm học."}, {"n": "6", "name": "Số HS chuyển đến (transfer in) đầu cấp", "desc": "Tổng số học sinh nhập học bổ sung đầu cấp từ trường khác trong năm học (lớp 6 và lớp 10)."}, {"n": "7", "name": "Tỉ lệ HS rút học trong năm", "desc": "([2]/[1])*100 Tỉ lệ % học sinh rút học so với tổng số học sinh đầu năm học."}, {"n": "8", "name": "Tỉ lệ HS rút học ở các năm chuyển cấp", "desc": "([4]/[3])*100 Tỉ lệ HS rút học ở các năm chuyển cấp"}, {"n": "9", "name": "Tỉ lệ HS chuyển đến ở các năm đầu cấp", "desc": "([4]/[3])*100 Tỉ lệ HS chuyển đến ở các năm đầu cấp"}, {"n": "10", "name": "Tỉ lệ tăng/giảm ròng qui mô HS", "desc": "(([1]-[2]+[5])/[1])*100 Tỉ lệ % thay đổi qui mô học sinh ròng trong năm học = (HS đầu năm – HS rút học + HS chuyển đến) / HS đầu năm."}], "cut": ["31/12", "31/7"], "cutNote": "kèm báo cáo quý khi phát sinh rút học", "review": ["Điểm [9] \"HS chuyển đến ở năm đầu cấp\" dùng lại công thức [4]/[3] của điểm [8]; nên là [6] chia HS đầu năm các lớp đầu cấp."], "out": "HT"}, {"c": "KPI 4", "n": "Giảm 50% thời gian thực hiện các thủ tục hành chính so với qui trình hiện tại", "def": "Chỉ số KPI này theo dõi mức độ nhanh chóng và hiệu quả hơn của nhà trường trong việc xử lí tất cả các loại qui trình hành chính – từ tuyển sinh, thanh toán học phí, phát hành bảng điểm đến phê duyệt đơn nghỉ, yêu cầu mua sắm và phối hợp sự kiện. - Đo lường thời gian tiết kiệm được: so sánh thời gian hiện tại để hoàn thành một qui trình với phiên bản đã được cải tiến, tinh gọn. - Phản ánh hiệu quả qui trình làm việc: loại bỏ các bước không cần thiết, điểm nghẽn và công việc trùng lặp. - Đánh giá tác động của số hóa: mức độ các giải pháp công nghệ giúp tăng tốc độ và nâng cao độ chính xác. - Đo lường tính phản hồi dịch vụ: mức độ nhanh chóng và thuận lợi mà cán bộ, học sinh và phụ huynh nhận được sự hỗ trợ từ nhà trường.", "why": "Việc cắt giảm một nửa thời gian xử lí hành chính không chỉ là về tốc độ – mà còn là về việc tạo ra trải nghiệm học đường tốt hơn cho tất cả mọi người: - Đối với giáo viên và nhân viên – ít thời gian cho giấy tờ hơn đồng nghĩa với nhiều thời gian hơn để tập trung vào học sinh, sự sáng tạo và phát triển nghề nghiệp. - Đối với học sinh – ít sự chậm trễ hơn trong việc phê duyệt, sắp xếp lịch học và xử lí yêu cầu giúp hành trình học tập của các em liền mạch và ít căng thẳng hơn. - Đối với phụ huynh – các qui trình nhanh chóng, minh bạch khiến mọi tương tác với LHBS trở nên dễ dàng hơn, từ đó xây dựng sự tin tưởng và hài lòng. - Đối với nhà trường – quản lí hiệu quả phản ánh hình ảnh hiện đại, chuyên nghiệp, thu hút các gia đình và đối tác. - Đối với sứ mệnh của chúng ta – mỗi phút tiết kiệm từ hành chính là thêm một phút cho giảng dạy, cố vấn và đổi mới. Tại LHBS, KPI này là cam kết chung trong việc tôn trọng thời gian của tất cả mọi người. Dù đó là một biểu mẫu tài chính, một yêu cầu sắp xếp lịch hay một đơn đăng kí sự kiện, mục tiêu của chúng ta là làm cho qui trình trở nên đơn giản, nhanh chóng và dễ chịu. Kết quả? Một ngôi trường vận hành trơn tru như đồng hồ, nơi giáo viên tập trung giảng dạy, học sinh tập trung học tập, và phụ huynh cảm thấy được chăm sóc – đồng thời củng cố danh tiếng của LHBS như một tổ chức hiện đại, thân thiện với phụ huynh.", "asp": "Đạt được mức tiết kiệm thời gian đáng kể thông qua số hóa và tái thiết kế qui trình vào năm 2027.", "unit": "% (phần trăm)", "method": "[Mức giảm % thời gian xử lí so với ban đầu] = (([Thời gian xử lí trung bình hiện tại] - [Thời gian xử lí trung bình sau cải tiến]) / [Thời gian xử lí trung bình hiện tại])*100", "split": "1. Qui trình 2. Mức độ hài lòng của người dùng (giáo viên, phụ huynh, học sinh)", "collect": "Ghi nhận thời gian thực hiện qui trình qua hệ thống quản lí (log thời gian). - Quan sát, đo thời gian thủ công với các qui trình chưa số hóa. - Khảo sát định kì mức độ hài lòng của người dùng.", "src": "Hệ thống quản lí trường học (SIS/ERP). - Hồ sơ hành chính lưu trữ tại các phòng ban. - Biểu mẫu khảo sát phụ huynh, giáo viên, học sinh.", "freq": "2 lần/năm: theo học kì (hạn chót 31/12 và 31/5). - Bổ sung khi có cải tiến qui trình lớn hoặc triển khai phần mềm mới.", "owner": "Chưa điền", "store": "Cơ sở dữ liệu điện tử nội bộ (Google Drive/SharePoint/ERP). - Hồ sơ bản cứng tại phòng Hành chính – Quản trị (lưu trữ tối thiểu 5 năm).", "analyze": "So sánh trực tiếp thời gian xử lí hiện tại và sau cải tiến. - Tính % giảm thời gian trung bình cho từng qui trình. - Phân tích xu hướng theo năm học và theo loại qui trình. - Đối chiếu với mức độ hài lòng người dùng.", "present": "Biểu đồ cột: thời gian xử lí trước/sau cải tiến. - Biểu đồ đường: xu hướng % giảm thời gian qua các năm. - Dashboard trực quan (màu xanh = đạt, màu đỏ = chưa đạt).", "verify": "Chưa điền", "report": "Báo cáo định kì trong cuộc họp Ban Giám hiệu (hàng tháng, hàng quí). - Báo cáo tóm tắt KPI trong báo cáo thường niên gửi HĐ Chiến lược. - Dashboard cập nhật online để BGH và các phòng ban theo dõi liên tục.", "pts": [{"n": "0", "name": "Danh mục các qui trình hành chính cần được cải tiến", "desc": "Danh sách toàn bộ các qui trình hành chính được đo lường (VD: tuyển sinh, đóng học phí, cấp phát học bạ, duyệt nghỉ phép, mua sắm, tổ chức sự kiện)."}, {"n": "1", "name": "Danh mục các qui trình hành chính được lựa chọn để cải tiến", "desc": "Danh sách top các qui trình hành chính được xác định ưu tiên để cải tiến."}, {"n": "2", "name": "Thời gian xử lí trung bình hiện tại", "desc": "Số phút/giờ/ngày cần thiết để hoàn thành một qui trình theo cách hiện tại (trước cải tiến)."}, {"n": "3", "name": "Thời gian xử lí trung bình sau cải tiến", "desc": "Số phút/giờ/ngày cần thiết để hoàn thành cùng một qui trình sau khi áp dụng cải tiến hoặc số hóa."}, {"n": "4", "name": "Trung bình số bước trong các qui trình hiện tại", "desc": "Trung bình số bước cần thực hiện trong qui trình cũ (để thấy mức độ phức tạp, chồng chéo)."}, {"n": "5", "name": "Trung bình số bước trong qui trình được số hóa sau cải tiến", "desc": "Trung bình số bước cần thực hiện trong qui trình mới (sau khi lược bỏ, hợp nhất, số hóa)."}, {"n": "6", "name": "Tỉ lệ % giảm thời gian xử lí", "desc": "(([2]–[3])/[2])*100 Mức giảm % thời gian xử lí so với ban đầu."}, {"n": "7", "name": "Mức độ số hóa qui trình", "desc": "([4]-[5])/[4])*100 Tỉ lệ % qui trình đã được số hóa xử lí trực tuyến/toàn bộ số bước trong qui trình."}, {"n": "8", "name": "Mức độ hài lòng của người dùng (giáo viên, phụ huynh, HS)", "desc": "Đánh giá mức độ nhanh chóng, thuận tiện và minh bạch khi thực hiện thủ tục sau cải tiến."}], "cut": ["31/12", "31/5"], "cutNote": "", "review": ["Điểm [7] \"Mức độ số hóa\" đang đo mức giảm số bước, chưa phải tỷ lệ bước được số hóa."], "out": "HT"}, {"c": "KPI 5", "n": "Đạt tỉ lệ chuyển đổi từ quan tâm → nhập học 30% và mức hài lòng 90%+ đối với hoạt động marketing, tuyển sinh và dịch vụ phụ huynh", "def": "Chỉ số KPI này có hai phần gắn kết: 1. Hiệu quả chuyển đổi – Mức độ LHBS biến sự quan tâm của các gia đình tiềm năng thành nhập học chính thức. Bao gồm: - Sự rõ ràng và hấp dẫn của thông điệp marketing. - Tính nhanh nhạy và chuyên nghiệp của đội ngũ tuyển sinh. - Sự thuyết phục từ các buổi tham quan trường, sự kiện và lớp học trải nghiệm. - Ấn tượng ban đầu mà phụ huynh và học sinh cảm nhận được qua từng tương tác với nhà trường. 2. Mức độ hài lòng của phụ huynh – Sự hài lòng của gia đình sau khi gia nhập, với tất cả các dịch vụ dành cho phụ huynh: từ giao tiếp, tổ chức sự kiện đến giải quiết vấn đề và qui trình thanh toán. - Điểm hài lòng này phản ánh niềm tin vào thương hiệu và sự gắn bó lâu dài. Kết hợp lại, các chỉ số này cho thấy LHBS đang làm tốt thế nào trong việc thu hút, chào đón và duy trì sự gắn kết của phụ huynh – học sinh từ lần tiếp xúc đầu tiên cho đến nhiều năm đồng hành cùng nhà trường.", "why": "Ấn tượng đầu tiên là mãi mãi. Một sự giới thiệu tích cực và truyền cảm hứng về LHBS sẽ định hình cả hành trình học tập của một gia đình tại trường. - Tỉ lệ chuyển đổi không chỉ là con số – mà còn là minh chứng rằng chương trình, cơ sở vật chất và con người của chúng ta thực sự đáp ứng nhu cầu và khát vọng của các gia đình. - Điểm hài lòng cao đồng nghĩa với sự trung thành. Phụ huynh hài lòng sẽ trở thành đại sứ cho LHBS, chia sẻ trải nghiệm tích cực và thu hút thêm nhiều gia đình khác. - Tuyển sinh mạnh mẽ tạo nên tính bền vững. Một dòng chảy ổn định của học sinh mới kết hợp với những gia đình gắn bó lâu dài giúp LHBS vững vàng về tài chính, từ đó tiếp tục đầu tư vào chất lượng. - Đây là KPI của tất cả mọi người. Từ cách trả lời điện thoại, sự chào đón thân thiện tại cổng trường, cho đến cách giáo viên tương tác với học sinh tiềm năng khi tham quan – mỗi nhân viên đều góp phần vào cả tỉ lệ chuyển đổi lẫn mức độ hài lòng. Khi đạt được KPI này, chúng ta đang gửi đi một thông điệp mạnh mẽ: “LHBS là nơi lời hứa trở thành hiện thực.” Gia đình không chỉ đến một lần – họ chọn chúng ta, gắn bó với chúng ta và tự hào chia sẻ lí do tại sao. Đó là cách chúng ta tăng trưởng không chỉ về số lượng, mà còn về danh tiếng và tầm ảnh hưởng.", "asp": "Duy trì tiêu chuẩn dịch vụ cao, đồng thời đạt mục tiêu chuyển đổi gần 1/3 số lượng quan tâm thành học sinh nhập học thực tế.", "unit": "% (phần trăm)", "method": "1. Tỉ lệ chuyển đổi inquiry → enrollment: [Tỉ lệ % inquiry ban đầu trở thành học sinh nhập học] = ([Số học sinh nhập học mới] / [Số lượng inquiry phát sinh từ chiến dịch])*100 2. Mức độ hài lòng của phụ huynh Tỉ lệ hài lòng tổng thể của phụ huynh = ([Tổng số phụ huynh đánh giá ≥ “hài lòng” ở tất cả hạng mục] / [Tổng số phụ huynh tham gia khảo sát])*100", "split": "1. Cấp học 2. Năm học 3. Theo thời điểm trong năm 4. Theo loại chiến dịch – Online (digital ads, social media) / Offline (sự kiện, tour trường, hội thảo).", "collect": "Phần 1 – Conversion Efficiency: Thu thập từ hệ thống CRM/Admissions. Mỗi inquiry được ghi nhận theo nguồn (website, hotline, sự kiện, giới thiệu,…), sau đó theo dõi trạng thái (inquiry → hồ sơ đăng kí → nhập học). Phần 2 – Parent Satisfaction: Khảo sát phụ huynh trực tuyến (Google Form/SurveyMonkey) hoặc khảo sát giấy sau khi tham gia sự kiện, hoạt động hoặc sau 1 học kì. Dữ liệu nhập thủ công vào hệ thống M&E.", "src": "Phòng Tuyển sinh & Marketing (dữ liệu inquiry, hồ sơ, nhập học). Phòng Chăm sóc Phụ huynh (dữ liệu khảo sát hài lòng).", "freq": "1. Conversion Efficiency: 3 lần/năm (31/8, 31/12, và 31/5) 2. Parent Satisfaction: khảo sát 2 lần/năm (cuối học kì I và cuối năm học), bổ sung khảo sát nhanh sau mỗi sự kiện lớn (open day, hội thảo).", "owner": "Phần Inquiry → Enrollment: Trưởng phòng Tuyển sinh & Marketing. - Phần Satisfaction: Chuyên viên Chăm sóc Phụ huynh.", "store": "Hệ thống CRM (inquiry, enrollment). - Thư mục M&E SharePoint (file khảo sát, bảng tổng hợp kết quả). - Báo cáo tổng hợp lưu tại Phòng Hành chính & M&E.", "analyze": "Conversion Efficiency: tính tỉ lệ inquiry → enrollment theo từng nguồn, cấp học, thời điểm. Parent Satisfaction: tính tỉ lệ phụ huynh “≥ hài lòng” cho từng chỉ số (#1–#5), sau đó tính điểm tổng hợp (#6) theo công thức trung bình cộng hoặc theo số phụ huynh hài lòng/tổng số.", "present": "Dashboard/biểu đồ cột & tròn để hiển thị tỉ lệ chuyển đổi theo nguồn và cấp học. - Biểu đồ radar hoặc stacked bar để hiển thị mức độ hài lòng theo từng chỉ số. - Báo cáo bảng KPI tổng hợp hằng kì.", "verify": "Chưa điền", "report": "Báo cáo ngắn gọn trình bày tại cuộc họp Ban Giám Hiệu mỗi học kì. - Tích hợp vào Báo cáo Chiến lược & KPI hằng năm của trường. - Chia sẻ bản tóm tắt (dashboard) với Hội đồng Chiến lược để theo dõi định kì.", "pts": [{"n": "1.1", "name": "Số chiến dịch (campaign) đã triển khai", "desc": "Bao nhiêu chiến dịch được thực hiện trong năm học."}, {"n": "1.2", "name": "Tổng chi phí cho các chiến dịch", "desc": "Tổng chi phí (nhân sự, quảng cáo, sự kiện, tài liệu, quà tặng, v.v.) cho các chiến dịch được thực hiện trong năm học."}, {"n": "1.3", "name": "Số lượng inquiry (quan tâm ban đầu) phát sinh từ chiến dịch", "desc": "Tổng số phụ huynh/học sinh liên hệ tìm hiểu thông tin (qua website, hotline, sự kiện, giới thiệu) phát sinh từ chiến dịch."}, {"n": "1.4", "name": "Số lượng hồ sơ đăng kí", "desc": "Số phụ huynh nộp hồ sơ chính thức sau giai đoạn inquiry."}, {"n": "1.5", "name": "Số học sinh nhập học mới", "desc": "Số học sinh chính thức ghi danh/nộp phí nhập học."}, {"n": "1.6", "name": "Tỉ lệ chuyển đổi inquiry → enrollment", "desc": "([1.5]/[1.3])*100 Tỉ lệ % inquiry ban đầu trở thành học sinh nhập học (đo ở cuối pipeline)."}, {"n": "1.7", "name": "Chi phí trên mỗi enrollment", "desc": "([1.2]/[1.5])*100 Chi phí cho các chiến dịch / số học sinh nhập học."}, {"n": "2.1", "name": "Điểm hài lòng về qui trình tuyển sinh", "desc": "Đánh giá mức độ hài lòng của phụ huynh về sự rõ ràng, nhanh chóng, chuyên nghiệp trong toàn bộ qui trình tuyển sinh."}, {"n": "2.2", "name": "Điểm hài lòng về dịch vụ chăm sóc phụ huynh", "desc": "Đánh giá mức độ hài lòng với các dịch vụ hỗ trợ sau khi nhập học: giao tiếp, giải quiết yêu cầu, thu học phí, và hoạt động gắn kết."}, {"n": "2.3", "name": "Điểm hài lòng về sự kiện & hoạt động trường", "desc": "Đánh giá sự hài lòng với việc tổ chức sự kiện, buổi họp, chương trình cộng đồng & campaigns (VD: hội thảo, open day, tour trường)."}, {"n": "2.4", "name": "Điểm mức độ nhận biết thương hiệu (brand awareness)", "desc": "Tỉ lệ phụ huynh biết đến và lựa chọn LHBS thông qua các kênh chiến dịch truyền thông và tuyển sinh."}, {"n": "2.5", "name": "Điểm mức độ sẵn sàng giới thiệu LHBS (Net Promoter Score)", "desc": "Tỉ lệ % phụ huynh sẵn sàng giới thiệu LHBS cho gia đình, bạn bè, hoặc cộng đồng khác."}, {"n": "2.6", "name": "Tỉ lệ hài lòng tổng thể của phụ huynh về chăm sóc khách hàng và tuyển sinh", "desc": "[1.1]+[1.2]+[1.3]+[1.4]+[1.5] Chỉ số tổng hợp từ các điểm 1–5, phản ánh tỉ lệ % phụ huynh đánh giá ≥ “hài lòng” về trải nghiệm toàn diện với LHBS. Lưu ý sử dụng trọng số hoặc phương pháp tính phù hợp để tránh sai sót về mặt thống kê (average of average)."}], "cut": ["31/8", "31/12", "31/5"], "cutNote": "hài lòng: khảo sát cuối HK1 và cuối năm học", "review": ["Điểm [1.7] \"Chi phí trên mỗi enrollment\" có ×100 và đơn vị %; nên là VNĐ/học sinh.", "Điểm [2.6] cộng [1.1]…[1.5]; đúng ra là các điểm hài lòng [2.1]…[2.5], tránh trung bình của trung bình.", "Rà soát CSDL (YF-06) đề nghị tách thành 2 mã: chuyển đổi và hài lòng.", "Phương án 19/10 ghi mã KPI 6 cho chỉ tiêu chuyển đổi: chờ xác nhận mã."], "out": "HT"}, {"c": "KPI 6", "n": "Thu hút & giữ chân đội ngũ chất lượng ≥90%-100%", "def": "Chỉ số KPI này theo dõi mức độ hiệu quả của nhà trường trong việc tuyển dụng, phát triển và giữ chân đội ngũ giáo viên và nhân sự tài năng – những người trực tiếp mang lại chất lượng giáo dục và dịch vụ hỗ trợ cao. Điều này bao gồm cả tỉ lệ duy trì nhân sự hiện tại và chất lượng nguồn ứng viên cho các vị trí tuyển mới. KPI 6 có thể được đánh giá theo ba khía cạnh quan trọng: - Duy trì (Ổn định): tỉ lệ giáo viên và nhân sự được giữ lại mỗi năm, phản ánh sự ổn định và cam kết của đội ngũ. - Tuyển dụng (Chất lượng Nguồn Ứng viên): Mức độ hấp dẫn của nhà trường trên thị trường lao động, được đo lường qua số lượng và chất lượng ứng viên đủ điều kiện cho mỗi vị trí tuyển dụng. - Phát triển (Tăng trưởng Nghề nghiệp): Mức độ và chất lượng tham gia các hoạt động phát triển nghề nghiệp, thể hiện việc LHBS đầu tư vào nâng cao năng lực và thúc đẩy sự gắn bó lâu dài. Nếu không tuyển thêm ai mới, công thức này = tỉ lệ giữ chân (Retention Rate). Nếu có tuyển thêm, chỉ số này phản ánh năng lực bù đắp và mở rộng nhân sự: - Nếu tuyển đủ hoặc hơn số nghỉ → tỉ lệ ≥100% (cho thấy trường vừa giữ được người, vừa thu hút thêm). - Nếu tuyển ít hơn số nghỉ → tỉ lệ <100% (cho thấy hụt nhân sự so với đầu năm).", "why": "Đội ngũ giáo viên và nhân sự xuất sắc là nền tảng cho thành công của LHBS. Một tập thể ổn định, giàu kĩ năng và có động lực sẽ đảm bảo chất lượng giảng dạy nhất quán, xây dựng mối quan hệ gắn bó với học sinh và phụ huynh, đồng thời nâng cao uy tín của nhà trường. tỉ lệ duy trì nhân sự cao cũng giúp giảm chi phí và hạn chế gián đoạn, trong khi việc thu hút các ứng viên hàng đầu cho thấy LHBS là nơi đáng mơ ước để làm việc và phát triển nghề nghiệp.", "asp": "Duy trì tỉ lệ giữ chân nhân sự hằng năm ở mức ≥100% trở lên và đảm bảo có nguồn ứng viên chất lượng cho các vị trí tuyển mới, với ít nhất 3 ứng viên đạt chuẩn cho mỗi vị trí. Bên cạnh đó, xây dựng văn hóa phát triển nghề nghiệp liên tục, trong đó 100% giáo viên tham gia các khóa đào tạo hằng năm phù hợp với ưu tiên chiến lược của LHBS.", "unit": "% (phần trăm)", "method": "1. Tỉ lệ giữ chân thuần: [tỉ lệ % giáo viên và nhân viên được giữ lại trong năm học] = ([Số học sinh nhập học mới] / [Tổng số GV & NV đầu năm học])*100 2. Tỉ lệ tuyển dụng thành công [Tỉ lệ hài lòng tổng thể của phụ huynh] = ([Số lượng tuyển dụng thành công] / [Số lượng giáo viên và nhân viên cần được tuyển dụng trong năm])*100 3. Tỉ lệ thu hút & giữ chân (([Tổng số GV & NV đầu năm học] - [Số GV & NV nghỉ việc trong năm] + [Số lượng tuyển dụng mới thành công trong năm])/[Tổng số GV & NV đầu năm học]))*100", "split": "1. Cấp học 2. Năm học 3. Theo loại nhân sự - Giáo viên (GV), Nhân viên hành chính (NV), Quản lí (tổ trưởng, trưởng bộ phận, ban giám hiệu) 4. Theo bộ môn/khối chuyên môn 5. Theo thâm niên công tác 6. Theo tình trạng hợp đồng - Toàn thời gian (full-time), Bán thời gian (part-time), Hợp đồng ngắn hạn / thời vụ 7. Theo lí do nghỉ việc (attrition) - Do cá nhân/gia đình, Do cơ hội nghề nghiệp khác (cạnh tranh từ trường khác), Do điều kiện tài chính/lương thưởng, Do môi trường làm việc, Do thuyên chuyển/di chuyển địa lí", "collect": "HR tổng hợp số liệu nhân sự đầu năm, cuối năm, số nghỉ việc, số tuyển dụng mới từ hồ sơ nhân sự. - Bộ phận tuyển dụng ghi nhận số lượng ứng viên nộp hồ sơ, ứng viên đạt chuẩn và tuyển dụng thành công. - Bộ phận đào tạo ghi nhận danh sách GV/NV tham gia bồi dưỡng, số giờ đào tạo. - Khảo sát nội bộ GV/NV (hằng năm) để đo mức độ hài lòng.", "src": "Hồ sơ nhân sự (HR records, hợp đồng lao động, quiết định nghỉ việc). - Hệ thống tuyển dụng (danh sách ứng viên, kết quả phỏng vấn). - Hồ sơ đào tạo & phát triển (training records, biên bản tập huấn). - Khảo sát nội bộ GV/NV (Google Form/Survey tool).", "freq": "Nhân sự đầu năm/cuối năm: 2 lần/năm (tháng 8 & tháng 5). - Nghỉ việc, tuyển dụng mới: cập nhật hằng quí. - Dữ liệu đào tạo: cập nhật sau mỗi khóa tập huấn, tổng hợp 1 lần/năm. - Khảo sát hài lòng: 1 lần/năm (tháng 5).", "owner": "Chưa điền", "store": "Hồ sơ nhân sự: hệ thống HRM & bản cứng tại phòng Hành chính – Nhân sự. - Dữ liệu tuyển dụng/đào tạo: lưu trên HRM và Google Drive nội bộ (folder HR). - Khảo sát hài lòng: lưu file kết quả (Excel/Google Sheet) trong thư mục HR – KPI.", "analyze": "Tính toán Retention Rate, Attrition Rate, Net Stability Rate. - So sánh số lượng tuyển dụng cần → ứng viên đạt chuẩn → tuyển dụng thành công → % lấp đầy. - Thống kê tỉ lệ tham gia đào tạo và giờ đào tạo trung bình. - Phân tích kết quả khảo sát hài lòng theo nhóm (giáo viên, nhân viên hành chính, quản lí).", "present": "Bảng biểu tổng hợp theo năm học (so sánh các năm). - Biểu đồ cột (tỉ lệ giữ chân, nghỉ việc). - Biểu đồ funnel (pipeline tuyển dụng: cần tuyển → ứng viên → đạt chuẩn → tuyển thành công). - Biểu đồ tròn (tỉ lệ tham gia đào tạo, lí do nghỉ việc).", "verify": "Chưa điền", "report": "Báo cáo KPI định kì: 2 lần/năm (giữa năm & cuối năm học). - Trình bày trong Báo cáo chiến lược & KPI toàn trường gửi Ban Giám hiệu và Hội đồng Chiến lược. - Tích hợp kết quả KPI 6 vào Dashboard KPI nội bộ (Google Data Studio hoặc Excel dashboard).", "pts": [{"n": "1.1", "name": "Tổng số GV & NV đầu năm học", "desc": "Tổng số giáo viên và nhân viên chính thức đang làm việc tại LHBS khi bắt đầu năm học."}, {"n": "1.2", "name": "Tổng số GV & NV ở lại đến cuối năm học", "desc": "Tổng số giáo viên và nhân viên vẫn đang làm việc tại LHBS khi kết thúc năm học (chỉ tính người ở lại, không tính người mới)."}, {"n": "1.3", "name": "Số GV & NV nghỉ việc trong năm", "desc": "Số lượng giáo viên và nhân viên rời trường trong năm học (bao gồm tự nguyện và không tự nguyện)."}, {"n": "1.4", "name": "Tỉ lệ giữ chân GV & NV thuần", "desc": "([1.2]/[1.1])*100 tỉ lệ % giáo viên và nhân viên được giữ lại trong năm học"}, {"n": "1.5", "name": "Tỉ lệ nghỉ việc GV & NV", "desc": "([1.3]/[1.1])*100 tỉ lệ % giáo viên và nhân viên rời trường trong năm học"}, {"n": "2.1", "name": "Số lượng giáo viên và nhân viên cần được tuyển dụng trong năm", "desc": "Tổng số vị trí cần tuyển dụng trong năm học (bao gồm thay thế do nghỉ việc và bổ sung cho mở rộng qui mô)."}, {"n": "2.2", "name": "Số lượng ứng viên cho các vị trí tuyển dụng", "desc": "Tổng số hồ sơ ứng tuyển cho từng vị trí tuyển dụng mở trong năm học."}, {"n": "2.3", "name": "Số lượng ứng viên đạt chuẩn cho các vị trí", "desc": "Số ứng viên đáp ứng đủ yêu cầu (≥3 ứng viên đạt chuẩn cho mỗi vị trí)."}, {"n": "2.4", "name": "Số lượng tuyển dụng thành công", "desc": "Tổng số giáo viên và nhân viên mới được tuyển dụng thành công, kí hợp đồng và chính thức gia nhập LHBS trong năm học."}, {"n": "2.5", "name": "Tỉ lệ tuyển dụng thành công", "desc": "([2.4]/[2.3])*100 tỉ lệ % vị trí tuyển dụng được lấp đầy bằng ứng viên đạt chuẩn."}, {"n": "3", "name": "Tỉ lệ thu hút & giữ chân", "desc": "(([1.1]-[1.3]+[2.4])/[1.1])*100 ((Tổng số GV & NV đầu năm học - Số GV & NV nghỉ việc trong năm + Số lượng tuyển dụng mới thành công trong năm)/Tổng số GV & NV đầu năm học))*100"}], "cut": ["31/8", "31/5"], "cutNote": "nghỉ việc, tuyển dụng cập nhật hằng quý", "review": ["Phương pháp tính \"giữ chân thuần\" dùng tử số \"Số học sinh nhập học mới\" (nhầm từ KPI 5); nhãn tỷ lệ tuyển dụng ghi nhầm \"hài lòng phụ huynh\".", "Tên KPI \"≥100%\" khác tiêu đề sheet \"≥90%–100%\". Rà soát (YF-06) đề nghị tách tuyển dụng và giữ chân."], "out": "HT"}, {"c": "KPI 7", "n": "Đạt tỉ suất lợi nhuận gộp 50% trên doanh thu từ các hoạt động giáo dục và dịch vụ bổ trợ (chỉ sử dụng nội bộ)", "def": "Chỉ số KPI này theo dõi mức độ hiệu quả của LHBS trong việc tạo ra và quản lí doanh thu từ các dịch vụ giáo dục cốt lõi và các chương trình bổ trợ – như câu lạc bộ STEM, khóa học ngoại ngữ, trại hè và các dịch vụ giá trị gia tăng khác – sau khi đã trang trải chi phí trực tiếp để vận hành chúng. - Đo lường sức khỏe tài chính: xác định phần thu nhập còn lại để tái đầu tư sau khi chi trả các chi phí thiết yếu cho việc triển khai chương trình. - Phản ánh hiệu quả vận hành: mức độ sử dụng hợp lí nguồn lực, thời gian nhân sự và cơ sở vật chất để tối đa hóa giá trị mà không gây lãng phí. - Thể hiện sự cân bằng giữa khả năng chi trả của phụ huynh và tính bền vững của nhà trường, đảm bảo vừa cung cấp dịch vụ chất lượng cao vừa giữ mức giá hợp lí.", "why": "Một tỷ suất lợi nhuận gộp mạnh mẽ không chỉ là một con số kế toán – mà chính là nguồn năng lượng cho tương lai của LHBS: - Đầu tư cho đổi mới – cho phép chúng ta nâng cấp cơ sở vật chất, triển khai các chương trình mới và giữ cho chương trình học luôn tươi mới, phù hợp. - Hỗ trợ con người – tạo điều kiện đầu tư vào đào tạo giáo viên, mức lương cạnh tranh và phát triển chuyên môn, mang lại lợi ích trực tiếp cho học sinh. - Đảm bảo sự ổn định – bảo vệ nhà trường khỏi các cú sốc tài chính và cho phép linh hoạt ứng phó với cơ hội hoặc thách thức mà không ảnh hưởng đến chất lượng. - Giữ giáo dục trong tầm tay phụ huynh – với biên lợi nhuận lành mạnh, chúng ta có thể quản lí chi phí một cách có trách nhiệm và tránh việc tăng học phí đột ngột, quá cao. Đối với tất cả mọi người tại LHBS – từ giáo viên đến nhân sự vận hành – KPI này nhắc nhở rằng hiệu quả tài chính là trách nhiệm chung. Mỗi lần chúng ta sử dụng nguồn lực khôn ngoan, thiết kế chương trình thu hút tuyển sinh tốt, hoặc mang đến dịch vụ chất lượng cao được phụ huynh đánh giá cao, chúng ta đều góp phần tạo ra biên lợi nhuận giúp LHBS truyền cảm hứng, đổi mới và dẫn đầu trong giáo dục nhiều năm tới.", "asp": "Không chỉ dừng lại ở việc đạt tỷ suất lợi nhuận gộp 50%, LHBS hướng tới xây dựng một mô hình tài chính bền vững để liên tục tái đầu tư cho sự xuất sắc. Khát vọng không chỉ là đạt chỉ tiêu lợi nhuận, mà còn là biến nó thành động lực cho đổi mới, nâng cao năng lực đội ngũ và giữ vững tính tiếp cận – bảo đảm LHBS luôn mang đến nền giáo dục đẳng cấp quốc tế, mở rộng các dịch vụ giá trị gia tăng, và tiếp tục là lựa chọn đáng tin cậy, hợp lí cho các gia đình qua nhiều năm.", "unit": "% (phần trăm)", "method": "[Tỉ lệ % lợi nhuận gộp trên tổng doanh thu gộp] = ([Biên lợi nhuận gộp]/[Tổng doanh thu gộp (giáo dục + bổ trợ)])*100", "split": "1. Doanh thu từ hoạt động giáo dục chính (học phí, chương trình đào tạo, khóa học). 2. Doanh thu từ dịch vụ bổ trợ (CLB STEM, ngoại ngữ, trại hè, dịch vụ hỗ trợ HS). 3. Chi phí trực tiếp hoạt động giáo dục chính (nhân sự giảng dạy, cơ sở vật chất, giáo trình, phòng học). 4. Chi phí trực tiếp dịch vụ bổ trợ (giảng viên, vận hành, trang thiết bị, marketing liên quan). 5. Cơ sở 6. Cấp học", "collect": "Thu thập số liệu từ hệ thống kế toán nội bộ và các báo cáo tài chính định kì. - Đối chiếu doanh thu và chi phí theo từng mảng hoạt động (giáo dục chính, bổ trợ). - Kiểm tra và xác nhận dữ liệu với các phòng ban liên quan trước khi nhập vào hệ thống KPI.", "src": "1. Tổng doanh thu từ hoạt động giáo dục chính: Báo cáo tài chính nội bộ, bao gồm học phí, chương trình đào tạo, khóa học, hoạt động giảng dạy. 2. Tổng doanh thu từ dịch vụ bổ trợ: Báo cáo doanh thu từ CLB STEM, ngoại ngữ, trại hè, dịch vụ hỗ trợ HS. 3. Tổng chi phí hoạt động giáo dục chính: Báo cáo chi phí nhân sự, cơ sở vật chất, giáo trình, vận hành giảng dạy. 4. Tổng chi phí dịch vụ bổ trợ: Báo cáo chi phí giảng viên, vận hành CLB, trại hè, marketing và dịch vụ liên quan.", "freq": "2 lần/năm (giữa năm tài chính và cuối năm tài chính). - Dữ liệu sơ bộ báo cáo quý, dữ liệu chính thức báo cáo năm.", "owner": "Chưa điền", "store": "Hệ thống kế toán nội bộ (ERP/Excel tổng hợp). - Thư mục dùng chung trên server LHBS với quiền truy cập hạn chế. - Bản cứng lưu tại Phòng Tài chính – Kế toán.", "analyze": "Tính toán lợi nhuận gộp và tỉ suất lợi nhuận gộp cho từng mảng hoạt động và toàn trường. - So sánh kết quả theo thời gian (năm này so với năm trước) và với mục tiêu 50%. - Phân tích nguyên nhân biến động (tăng/giảm doanh thu, chi phí).", "present": "Báo cáo bằng bảng và biểu đồ (cột/đường) thể hiện xu hướng biên lợi nhuận gộp. - Dashboard trực quan trong báo cáo tài chính/kế hoạch chiến lược.", "verify": "Chưa điền", "report": "Báo cáo nội bộ định kì 2 lần/năm cho Ban Giám đốc. - Trình bày trong báo cáo KPI thường niên, phục vụ đánh giá mục tiêu chiến lược.", "pts": [{"n": "1", "name": "Tổng doanh thu từ dịch vụ giáo dục chính", "desc": "Tổng doanh thu hàng năm từ học phí và các chương trình đào tạo chính qui của LHBS."}, {"n": "2", "name": "Tổng doanh thu từ dịch vụ bổ trợ", "desc": "Tổng doanh thu hàng năm từ các chương trình bổ trợ như CLB STEM, khóa ngoại ngữ, trại hè, và dịch vụ giá trị gia tăng khác (ăn uống, kí túc xá, đưa đón, v.v...)."}, {"n": "3", "name": "Tổng doanh thu gộp (giáo dục + bổ trợ)", "desc": "[1]+[2] Tổng doanh thu kết hợp từ dịch vụ giáo dục chính và bổ trợ."}, {"n": "4", "name": "Tổng chi phí trực tiếp của dịch vụ giáo dục chính", "desc": "Tổng chi phí trực tiếp để tổ chức và vận hành các chương trình đào tạo chính (giảng dạy, tài liệu, phòng học, trang thiết bị, v.v.)."}, {"n": "5", "name": "Tổng chi phí trực tiếp của dịch vụ bổ trợ", "desc": "Tổng chi phí trực tiếp để tổ chức các dịch vụ bổ trợ (giảng viên, cơ sở vật chất, vật tư, marketing liên quan, v.v.)."}, {"n": "6", "name": "Tổng chi phí trực tiếp (giáo dục + bổ trợ)", "desc": "[4]+[5] Tổng chi phí trực tiếp để vận hành cả dịch vụ giáo dục chính và bổ trợ."}, {"n": "7", "name": "Biên lợi nhuận gộp từ hoạt động giáo dục chính", "desc": "[1]-[4] Doanh thu từ hoạt động giáo dục chính (1) - chi phí trực tiếp của hoạt động giáo dục chính (4)"}, {"n": "8", "name": "Tỉ suất lợi nhuận gộp (Gross Profit Margin) từ hoạt động giáo dục chính", "desc": "([7]/[1])*100"}, {"n": "9", "name": "Biên lợi nhuận gộp từ dịch vụ bổ trợ", "desc": "[2]-[5] Doanh thu từ dịch vụ bổ trợ (2) - chi phí trực tiếp của dịch vụ bổ trợ (5)"}, {"n": "10", "name": "Tỉ suất lợi nhuận gộp (Gross Profit Margin) từ dịch vụ bổ trợ", "desc": "([9]/[2])*100"}, {"n": "11", "name": "Biên lợi nhuận gộp", "desc": "[3]-[6] Doanh thu gộp trừ đi tổng chi phí trực tiếp."}, {"n": "12", "name": "Tỉ suất lợi nhuận gộp (Gross Profit Margin)", "desc": "([11]/[6])*100"}], "cut": ["30/6", "31/12"], "cutNote": "giữa và cuối năm tài chính; ngày cụ thể là giả định theo năm dương lịch", "review": ["Điểm [12] chia cho tổng chi phí [6], trong khi phương pháp tính ghi chia cho doanh thu gộp [3].", "Phương án 19/10 ghi mã KPI 4 cho lợi nhuận gộp: chờ xác nhận mã."], "out": "HT"}, {"c": "1.1.1", "n": "Đạt công nhận quốc tế về chất lượng giáo dục tại LHBS", "def": "Chỉ số KPI này theo dõi việc LHBS có đạt được chứng nhận kiểm định chính thức từ một tổ chức giáo dục quốc tế uy tín hay không, chẳng hạn như Hội đồng Các Trường Quốc tế (CIS). Việc kiểm định khẳng định rằng chương trình học, phương pháp giảng dạy, hỗ trợ học sinh, cơ sở vật chất, năng lực lãnh đạo và hoạt động của nhà trường đều đáp ứng các tiêu chuẩn chất lượng được công nhận toàn cầu. Đây không chỉ là một tấm chứng nhận – mà là một quá trình đánh giá toàn diện, khách quan từ bên ngoài đối với mọi khía cạnh của nhà trường, từ giảng dạy trên lớp đến quản trị và gắn kết cộng đồng. Quy trình bao gồm tự đánh giá, đánh giá đồng cấp và cam kết cải tiến liên tục – đảm bảo rằng chúng ta không chỉ “tốt cho hôm nay” mà còn hướng tới sự xuất sắc bền vững.", "why": "Xây dựng niềm tin ngay lập tức – Phụ huynh và đối tác trên toàn thế giới công nhận kiểm định như một minh chứng rằng LHBS ngang tầm với các trường quốc tế hàng đầu. - Tăng cường quan hệ hợp tác – Các trường được kiểm định sẽ thu hút cơ hội hợp tác, trao đổi và triển khai chương trình với những tổ chức giáo dục chất lượng cao khác. - Thúc đẩy cải tiến nội bộ – qui trình khắt khe bảo đảm mọi bộ phận – học thuật, vận hành và hỗ trợ – đều nâng cao năng lực và duy trì trách nhiệm giải trình. - Định vị LHBS là trường dẫn đầu tại Đồng Nai – Chúng ta không chỉ đáp ứng kì vọng địa phương mà còn đặt ra chuẩn mực quốc tế, đồng thời vẫn giữ vững bản sắc Việt Nam. Khi đạt được KPI này, LHBS có thể tự hào nói: “Chúng tôi không chỉ là ngôi trường được lựa chọn tại Đồng Nai – chúng tôi là một trường học xuất sắc được công nhận toàn cầu.”", "asp": "Đạt chứng nhận kiểm định vào năm 2030 như một dấu ấn hiển nhiên của sự xuất sắc.", "unit": "Trạng thái / % tiến độ theo giai đoạn kiểm định", "method": "1. Giai đoạn tiến độ: theo dõi mức độ hoàn thành từng bước của qui trình kiểm định quốc tế (VD: Membership, Preparatory Evaluation, Self-Study, Team Evaluation, Accreditation Decision). 2. Giá trị KPI: [Tỉ lệ hoàn thành các hạng mục cải tiến] = ([Số lượng qui trình/hệ thống đã được điều chỉnh] / [Số lượng qui trình/hệ thống cần được điều chỉnh])*100", "split": "1. Hồ sơ đăng kí Membership và tài liệu CIS. 2. Báo cáo tự đánh giá (Self-Study Reports). 3. Biên bản/feedback từ đoàn kiểm định (Preparatory Evaluation, Team Evaluation). 4. Kế hoạch cải tiến (Action Plan). 5. Thông báo kết quả chính thức từ CIS.", "collect": "Thu thập và lưu trữ tất cả các tài liệu chính thức liên quan đến qui trình kiểm định quốc tế (membership letter, self-study report, evaluation feedback, accreditation decision). Tổng hợp tiến độ và mức độ hoàn thành từng giai đoạn trong hệ thống quản lí chất lượng ISO 21001.", "src": "1. Hồ sơ và tài liệu chính thức từ CIS. 2. Báo cáo nội bộ từ Ban Đảm bảo Chất lượng LHBS. 3. Biên bản họp Ban Giám hiệu và Hội đồng Kiểm định.", "freq": "2 lần/năm: sau mỗi kì nộp báo cáo và sau mỗi chuyến thăm đánh giá. Báo cáo bổ sung ngay khi có cập nhật quan trọng từ CIS.", "owner": "Chưa điền", "store": "Bộ phận Đảm bảo Chất lượng, phối hợp lưu trữ trên hệ thống ISO 21001:2018 (dạng số và bản cứng).", "analyze": "1. So sánh tiến độ thực tế với timeline chuẩn của CIS. 2. Đối chiếu các khuyến nghị từ đoàn kiểm định với kế hoạch cải tiến của LHBS. 3. Đánh giá mức độ hoàn thành (%).", "present": "1. Dashboard trực quan theo các giai đoạn kiểm định (timeline %). 2. Báo cáo định kì với trạng thái (Chưa bắt đầu / Đang tiến hành / Hoàn thành).", "verify": "Chưa điền", "report": "1. Báo cáo nội bộ hàng quý cho Hội đồng Chiến lược và Ban Giám hiệu. 2. Báo cáo thường niên gắn trong KPI Institutional Scorecard. 3. Trình bày tại các cuộc họp chiến lược và trong báo cáo đối tác khi có yêu cầu.", "pts": [{"n": "1.1", "name": "Cơ quan kiểm định quốc tế lựa chọn", "desc": "Tổ chức kiểm định mà LHBS đăng kí (VD: CIS, WASC) - báo cáo phân tích chiến lược về cơ quan kiểm định (lí do, lợi ích, các tiêu chuẩn, lộ trình v.v...)"}, {"n": "1.2", "name": "Tình trạng đăng kí kiểm định / Membership – Trở thành thành viên CIS", "desc": "Đã nộp hồ sơ & được công nhận là thành viên CIS hay chưa."}, {"n": "1.3", "name": "Thành lập Ban chỉ đạo kiểm định & nhóm phụ trách Self-Study.", "desc": "Thiết lập cơ cấu lãnh đạo và nhóm chuyên trách để điều phối toàn bộ tiến trình kiểm định, phân công trách nhiệm và giám sát việc tự đánh giá theo tiêu chuẩn CIS."}, {"n": "1.4", "name": "Hoàn thành & nộp Preparatory Self-Study Report.", "desc": "Thực hiện báo cáo tự đánh giá ban đầu, phản ánh mức độ đáp ứng các tiêu chuẩn CIS và gửi cho tổ chức kiểm định để xem xét."}, {"n": "1.5", "name": "Đón đoàn Preparatory Evaluation Visit", "desc": "Tiếp đoàn đánh giá sơ bộ của CIS đến trường để quan sát, phỏng vấn và xác minh thông tin trong báo cáo tự đánh giá."}, {"n": "1.6", "name": "Kết quả Preparatory Evaluation Visit", "desc": "Kết quả & khuyến nghị từ đoàn CIS sau đợt đánh giá chuẩn bị."}, {"n": "1.7", "name": "Xây dựng & triển khai Action Plan/Preparatory Review Report dựa trên khuyến nghị.", "desc": "Trường xây dựng kế hoạch hành động (Action Plan) để khắc phục các điểm còn yếu theo khuyến nghị từ đoàn Preparatory Evaluation."}, {"n": "1.8", "name": "Kế hoạch cải tiến sau khuyến nghị (Action Plan)", "desc": "Trường xây dựng kế hoạch hành động (Action Plan) để khắc phục các điểm còn yếu theo khuyến nghị từ đoàn Preparatory Evaluation."}, {"n": "1.9", "name": "Xác nhận Candidacy / Sẵn sàng Team Evaluation", "desc": "CIS xác nhận trường đã sẵn sàng bước vào giai đoạn Team Evaluation. Thông thường trường trở thành “CIS Candidate for Accreditation”."}, {"n": "1.1", "name": "Tiến hành Full Self-Study toàn diện", "desc": "Thực hiện tự đánh giá toàn diện tất cả các mặt hoạt động, lĩnh vực (giảng dạy, quản trị, học sinh, cộng đồng) của trường theo tiêu chuẩn quốc tế, làm cơ sở cho đánh giá chính thức."}, {"n": "1.11", "name": "Hoàn thành Full Self-Study Report", "desc": "Trường thực hiện một báo cáo tự đánh giá toàn diện (Full Self-Study), dựa trên các tiêu chuẩn của CIS. Đây là tài liệu chính mà đoàn Team Evaluation sẽ sử dụng khi đến đánh giá."}, {"n": "1.12", "name": "Hoàn thành Team Evaluation Visit (đánh giá chính thức)", "desc": "Trạng thái: chưa thực hiện / đang tiến hành / đã hoàn tất."}, {"n": "1.13", "name": "Hoàn tất rà soát cuối cùng, chuẩn bị hồ sơ cho Hội đồng CIS.", "desc": "Tổng hợp kết quả đánh giá, hoàn thiện minh chứng và nộp đầy đủ hồ sơ để Hội đồng CIS xem xét đưa ra quiết định công nhận kiểm định."}, {"n": "1.14", "name": "Kết quả Accreditation Decision", "desc": "Quyết định chính thức: đạt / đạt có điều kiện / chưa đạt."}, {"n": "1.15", "name": "Thời hạn hiệu lực công nhận", "desc": "Số năm hiệu lực công nhận CIS."}, {"n": "1.16", "name": "Trạng thái duy trì & tái kiểm định", "desc": "Mức độ tuân thủ & chuẩn bị cho chu kì re-accreditation."}, {"n": "2.1", "name": "Số lượng qui trình/hệ thống cần được điều chỉnh", "desc": "Số qui trình học thuật, quản trị, hỗ trợ học sinh cần được cải tiến để đáp ứng chuẩn quốc tế."}, {"n": "2.2", "name": "Số lượng qui trình/hệ thống đã được điều chỉnh", "desc": "Số qui trình học thuật, quản trị, hỗ trợ học sinh đã cải tiến để đáp ứng chuẩn quốc tế."}, {"n": "2.3", "name": "Tỉ lệ hoàn thành các hạng mục cải tiến", "desc": "% hạng mục cải tiến đã hoàn tất so với tổng số hạng mục."}], "cut": [], "cutNote": "theo sự kiện: sau mỗi kỳ nộp báo cáo và mỗi chuyến thăm đánh giá", "review": [], "out": "1.1"}, {"c": "1.1.2", "n": "Tăng cường sự tham gia của học sinh vào các chương trình quốc tế (không do LHBS chủ trì)", "def": "Chỉ số KPI này theo dõi tỉ lệ học sinh LHBS tham gia các trải nghiệm học tập quốc tế hằng năm ((không do LHBS chủ trì) thông qua các mối quan hệ hợp tác của nhà trường. Các hoạt động có thể bao gồm: - Trao đổi học sinh với các trường đối tác ở nước ngoài. - Tham gia các cuộc thi quốc tế về học thuật, nghệ thuật, STEM hoặc thể thao. - Hợp tác trực tuyến và các dự án chung với học sinh từ các quốc gia khác. - Các chuyến du học ngắn hạn hoặc trại hè quốc tế. KPI này phản ánh mức độ nhà trường mở ra cơ hội cho học sinh áp dụng việc học trong bối cảnh toàn cầu.", "why": "Xây dựng năng lực toàn cầu – Học sinh phát triển kĩ năng giao tiếp xuyên văn hóa, khả năng thích ứng và hợp tác – những kĩ năng thiết yếu của thế kỉ 21. - Tăng sự tự tin – Việc đại diện cho LHBS và Việt Nam trên sân khấu quốc tế là một trải nghiệm trưởng thành mạnh mẽ đối với bất kì học sinh nào. - Khơi dậy hoài bão – Tiếp xúc với các nền văn hóa và cơ hội khác nhau khuyến khích học sinh mơ ước lớn hơn và phấn đấu cao hơn, cả về học tập lẫn cuộc sống. - Nâng cao uy tín nhà trường – Mỗi lần học sinh LHBS tỏa sáng ở quốc tế, thương hiệu của chúng ta càng được củng cố, chứng minh rằng chương trình giáo dục LHBS chuẩn bị cho học sinh thành công ở bất cứ đâu. Bằng việc đạt được KPI này, LHBS chứng minh rằng “học tập toàn cầu” không chỉ là khẩu hiệu – mà là trải nghiệm thực tế mà học sinh được sống, trải qua và mang theo trong tương lai.", "asp": "Tăng tỉ lệ tham gia từ 5% mỗi năm lên 10% vào năm 2030.", "unit": "% (phần trăm học sinh tham gia).", "method": "[Tỉ lệ % HS tham gia chương trình quốc tế] = ([Số cá nhân HS tham gia chương trình & hoạt động quốc tế (không trùng lặp)] / [Tổng số học sinh toàn trường])*100", "split": "1. Cấp học (Mầm non, Tiểu học, THCS, THPT) 2. Khối lớp 3. Năm học 4. Loại hình chương trình quốc tế: - Trao đổi quốc tế (exchange). - Trại hè/tour du học ngắn hạn. - Cuộc thi quốc tế (học thuật, STEM, nghệ thuật, thể thao). - Hợp tác trực tuyến/joint project quốc tế.", "collect": "Mỗi hoạt động quốc tế phải có danh sách học sinh tham gia (ghi rõ họ tên, lớp, loại hình hoạt động). - Bộ phận phụ trách tổng hợp danh sách, loại bỏ trùng lặp để xác định số cá nhân học sinh tham gia. - Đối chiếu với tổng số học sinh toàn trường theo sổ điểm danh chính thức.", "src": "Báo cáo từ Phòng Quan hệ Quốc tế & Hợp tác. - Danh sách tham gia hoạt động do giáo viên phụ trách/đơn vị tổ chức cung cấp. - Hệ thống quản lí học sinh (Student Information System – SIS).", "freq": "2 lần/năm, cuối học kì, tổng hợp báo cáo cuối năm học. - Cập nhật bổ sung ngay sau khi có hoạt động quốc tế lớn (VD: trại hè, cuộc thi quốc tế).", "owner": "Chưa điền", "store": "Bộ phận Hợp tác Quốc tế (dạng số và bản cứng). - Lưu trữ đồng thời trên hệ thống ISO 21001:2018 và SIS để đối chiếu.", "analyze": "Tính tổng số học sinh tham gia theo từng loại hoạt động. - Loại bỏ trùng lặp để xác định số cá nhân duy nhất. - Tính % trên tổng số học sinh toàn trường. - So sánh xu hướng qua các năm để đánh giá tốc độ tăng trưởng (5% → 10% đến 2030).", "present": "Biểu đồ cột/đường theo từng năm để thể hiện % tham gia. - Biểu đồ tròn để phân tích tỉ trọng theo loại hoạt động (exchange, competition, tour, online). - Bảng số liệu minh chứng (có danh sách HS).", "verify": "Chưa điền", "report": "Báo cáo KPI hằng năm trong Institutional KPI Scorecard. - Trình bày tại họp Hội đồng Chiến lược & Ban Giám hiệu. - Chia sẻ tóm tắt trong báo cáo thường niên để phụ huynh và đối tác nắm được kết quả.", "pts": [{"n": "1", "name": "Tổng số học sinh toàn trường", "desc": "Số lượng HS ghi danh tại LHBS trong năm học (mẫu số để tính tỉ lệ %)."}, {"n": "2", "name": "Số lượt HS tham gia giao lưu (exchange)", "desc": "Tổng số lượt học sinh tham gia các chương trình giao lưu học tập, văn hóa hoặc trao đổi (trong nước hoặc quốc tế) trong năm học."}, {"n": "3", "name": "Số lượt HS tham gia trại hè / tour du học ngắn hạn", "desc": "Số lượt học sinh tham gia các khóa học hè, study tour, camp quốc tế."}, {"n": "4", "name": "Số lượt HS tham gia cuộc thi quốc tế", "desc": "Số lượt học sinh đại diện LHBS thi học thuật, STEM, nghệ thuật, thể thao ở cấp khu vực hoặc quốc tế."}, {"n": "5", "name": "Số lượt HS tham gia dự án hợp tác trực tuyến quốc tế", "desc": "Số lượt học sinh tham gia lớp học ảo, joint project, hoặc competition online với học sinh nước ngoài."}, {"n": "6", "name": "Số cá nhân HS tham gia chương trình & hoạt động quốc tế (không trùng lặp)", "desc": "Tổng số học sinh duy nhất có tham gia ít nhất một hoạt động quốc tế trong năm học, loại bỏ trùng lặp."}, {"n": "7", "name": "Tổng số lượt HS tham gia trao đổi quốc tế (có thể trùng nếu một HS tham gia nhiều loại hình)", "desc": "[2]+[3]+[4]+[5] Tổng số lượt học sinh tham gia các chương trình trao đổi ngắn hạn/dài hạn với trường đối tác ở nước ngoài. Có thể trùng các cá nhân, tính theo lượt nếu một HS tham gia nhiều loại hình."}, {"n": "8", "name": "Tỉ lệ % HS tham gia chương trình quốc tế", "desc": "([6]/[1])*100 Tỉ lệ % HS tham gia ít nhất một chương trình quốc tế so với tổng số HS toàn trường."}, {"n": "9", "name": "Mức tăng trưởng tuyệt đối – Số lượt HS tham gia trao đổi quốc tế", "desc": "[7] năm nay - [7] năm trước Chênh lệch số lượt học sinh tham gia trao đổi quốc tế so với năm trước."}, {"n": "10", "name": "Mức tăng trưởng % – Số lượt HS tham gia trao đổi quốc tế", "desc": "(([7] năm nay - [7] năm trước)/[7] năm trước)*100 Tỉ lệ % tăng hoặc giảm số lượt học sinh tham gia trao đổi quốc tế so với năm trước."}], "cut": ["31/12", "31/5"], "cutNote": "", "review": [], "out": "1.1"}, {"c": "1.2.1", "n": "Tăng tỉ lệ học sinh đạt mức \"Thành thạo\" hoặc cao hơn theo thang năng lực ≥80%", "def": "Chỉ số KPI này theo dõi tỉ lệ học sinh đạt hoặc vượt mức “Thành thạo” theo khung năng lực của LHBS – bao gồm các môn học, kĩ năng/năng lực bổ trợ, các phẩm chất phát triển cá nhân, năng khiếu & kĩ năng thế kỉ 21 (tư duy phản biện, hợp tác, sáng tạo, giao tiếp). - Thang năng lực được xây dựng theo chuẩn mực quốc tế, đảm bảo kì vọng của chúng ta ngang tầm với các trường hàng đầu thế giới. - “Thành thạo” có nghĩa là học sinh có thể áp dụng kiến thức và kĩ năng một cách độc lập và nhất quán – chứ không chỉ ghi nhớ để làm bài kiểm tra. - Dữ liệu được thu thập từ nhiều nguồn: bài tập thực hành, dự án, hồ sơ học tập và các bài đánh giá chính thức.", "why": "Minh chứng cho việc học thật sự – Không chỉ là điểm số; mà là học sinh có thể vận dụng những gì đã học. - Hỗ trợ học tập cá nhân hóa – Việc theo dõi năng lực giúp giáo viên xác định ai cần thử thách thêm, ai cần hỗ trợ thêm để điều chỉnh phù hợp. - Xây dựng sự tự tin và sẵn sàng – Học sinh đạt mức thành thạo sẽ sẵn sàng cho bước tiếp theo – từ các cấp học cao hơn đến đại học hoặc môi trường làm việc. - Tín hiệu chất lượng cho phụ huynh và đối tác – tỉ lệ thành thạo cao cho thấy phương pháp giáo dục của LHBS hiệu quả và đáng tin cậy. Đạt được KPI này có nghĩa là LHBS có thể tự tin khẳng định: “Học sinh của chúng ta không chỉ học – các em đang làm chủ kĩ năng để sẵn sàng thành công ở bất cứ đâu trên thế giới.”", "asp": "Đạt 80% tỉ lệ thành thạo vào năm 2026.", "unit": "% (phần trăm học sinh)", "method": "[Tỉ lệ % HS đạt mức \"Thành thạo+\"] = (([Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Học thuật] + [Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Kĩ năng / năng lực bổ trợ] + Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Phát triển cá nhân, Năng khiếu & Kĩ năng thế kỉ 21])/([Số HS được đánh giá ở lĩnh vực Học thuật] + [Số HS được đánh giá ở lĩnh vực Kĩ năng / năng lực bổ trợ] + [Số HS được đánh giá ở lĩnh vực Phát triển cá nhân, Năng khiếu & Kĩ năng thế kỉ 21]))*100", "split": "1. Cấp học (Mầm non, Tiểu học, THCS, THPT) 2. Khối lớp 3. Năm học 4. Lĩnh vực - (Học thuật, kĩ năng thế kỉ 21, Phát triển cá nhân) 5. Môn học", "collect": "Giáo viên sử dụng bộ công cụ đánh giá chuẩn (rubric, portfolio, bài kiểm tra, quan sát, dự án). - Kết quả được nhập vào hệ thống quản lí học sinh (SIS). - Phòng Học vụ tổng hợp và loại trùng, phân loại theo từng lĩnh vực năng lực.", "src": "Kết quả đánh giá học tập & kĩ năng trên SIS. - Portfolio và dự án học sinh. - Phiếu quan sát/đánh giá định kì từ giáo viên.", "freq": "2 lần/năm: cuối học kì 1 và cuối năm học (hạn chót 31/12 và 31/5). - Đánh giá bổ sung sau các dự án trọng điểm (capstone, cuộc thi, triển lãm).", "owner": "Chưa điền", "store": "Hệ thống SIS (Student Information System). - Lưu trữ báo cáo tổng hợp tại Phòng Học vụ.", "analyze": "Tính % học sinh đạt Proficient+ trên toàn trường. - Phân tích theo lĩnh vực năng lực, cấp học, và xu hướng năm → năm. - So sánh với mục tiêu (≥80% vào năm 2026).", "present": "Biểu đồ cột theo % Proficient+ từng lĩnh vực năng lực. - Biểu đồ đường theo xu hướng toàn trường qua các năm. - Dashboard phân tích theo cấp học (Mầm non, Tiểu học, THCS, THPT).", "verify": "Chưa điền", "report": "Báo cáo KPI hằng năm trong Institutional Scorecard. - Báo cáo tổng hợp tại họp Hội đồng Chiến lược & Ban Giám hiệu. - Tóm tắt kết quả chính (overall % và highlights) trong báo cáo thường niên gửi phụ huynh và đối tác.", "pts": [{"n": "1.1", "name": "Tổng số học sinh được đánh giá bằng thang năng lực theo lĩnh vực Học thuật (Academic Competencies)", "desc": "Số HS được đánh giá theo thang năng lực ở các môn học chính khóa (Toán, Khoa học Tự nhiên, Ngữ văn, Ngoại ngữ, Khoa học Xã hội)."}, {"n": "1.2", "name": "Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Học thuật (Academic Competencies)", "desc": "Đếm số lượng học sinh được đánh giá ở mức \"Thành thạo+\" ở các môn chính khóa (Toán, Khoa học Tự nhiên, Ngữ văn, Ngoại ngữ, Khoa học Xã hội)."}, {"n": "1", "name": "Tỉ lệ % HS đạt mức \"Thành thạo+\" ở lĩnh vực Học thuật (Academic Competencies)", "desc": "([1.2]/[1.1])*100 Tỉ lệ HS đạt mức \"Thành thạo+\" hoặc cao hơn trong lĩnh vực học thuật."}, {"n": "2.1", "name": "Tổng số học sinh được đánh giá bằng thang năng lực theo lĩnh vực Kĩ năng / năng lực bổ trợ", "desc": "Số HS được đánh giá về tư duy kĩ năng / năng lực bổ trợ: - STEM - JA - AI Robotics"}, {"n": "2.2", "name": "Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Kĩ năng / năng lực bổ trợ", "desc": "Đếm số lượng học sinh được đánh giá ở mức \"Thành thạo+\" ở các môn kĩ năng / năng lực bổ trợ (STEM, JA, AI Robotics)"}, {"n": "2", "name": "Tỉ lệ % HS đạt mức \"Thành thạo+\" ở lĩnh vực Kĩ năng / năng lực bổ trợ", "desc": "([2.2]/[2.1])*100 Tỉ lệ HS đạt mức \"Thành thạo+\" hoặc cao hơn về kĩ năng / năng lực bổ trợ"}, {"n": "3.1", "name": "Tổng số học sinh được đánh giá bằng thang năng lực theo lĩnh vực Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21", "desc": "Số HS đánh giá về Phát triển cá nhân (Tinh thần trách nhiệm & kỷ luật, Khả năng thích ứng (Adaptability), Lòng nhân ái & đồng cảm (Empathy), Lãnh đạo & chủ động (Leadership & Initiative)), Năng khiếu & Kĩ năng thế kỉ 21 (phản biện, giao tiếp, hợp tác, sáng tạo)"}, {"n": "3.2", "name": "Số HS đạt mức \"Thành thạo+\" theo lĩnh vực Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21", "desc": "Đếm số lượng học sinh được đánh giá ở mức \"Thành thạo+\" ở lĩnh vực Phát triển cá nhân (trách nhiệm, thích ứng, nhân ái, lãnh đạo), năng khiếu & kĩ năng thế kỉ 21."}, {"n": "3", "name": "Tỉ lệ % HS đạt mức \"Thành thạo+\" ở lĩnh vực Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21", "desc": "([3.2]/[3.1])*100 Tỉ lệ HS đạt mức \"Thành thạo+\" hoặc cao hơn ở lĩnh vực Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21."}, {"n": "4", "name": "Tỉ lệ % HS đạt mức \"Thành thạo+\" các khía cạnh được đánh giá", "desc": "(([1.2]+[2.2]+[3.2])/([1.1]+[2.1]+[3.1]))*100 Tỉ lệ HS đạt mức \"Thành thạo+\" hoặc cao hơn đồng thời ở các khía cạnh được đánh giá."}], "cut": ["31/12", "31/5"], "cutNote": "", "review": [], "out": "1.2"}, {"c": "1.2.2", "n": "Tăng mức độ Hài lòng của phụ huynh về tiến bộ năng lực của học sinh ≥90%", "def": "Chỉ số KPI này đo lường mức độ hài lòng của phụ huynh về sự tiến bộ học tập, phát triển kĩ năng và trưởng thành cá nhân của con em mình tại LHBS. - Dựa trên khảo sát phụ huynh có cấu trúc và các kênh phản hồi, KPI này phản ánh mức độ phụ huynh nhận thấy nhà trường đang nuôi dưỡng tài năng và thế mạnh của từng học sinh như thế nào. - Không chỉ dừng ở điểm số – mà còn bao gồm nhận định của phụ huynh về sự giao tiếp từ giáo viên, hệ thống hỗ trợ, và việc kết quả học tập có đáp ứng kì vọng hay không. | J=Bổ sung định nghĩ riêng cho THCS-THT theo thông tư 29 (đạt/không đạt)", "why": "Phụ huynh là đối tác – Ý kiến của họ giúp chúng ta hoàn thiện phương pháp giảng dạy và hệ thống hỗ trợ. - Niềm tin là nền tảng – Mức độ hài lòng cao cho thấy các gia đình tin tưởng vào sứ mệnh, phương pháp và giá trị của LHBS. - Duy trì và giới thiệu – Phụ huynh hài lòng có xu hướng cho con tiếp tục học tại LHBS và giới thiệu trường cho người khác, tác động trực tiếp đến sự phát triển và ổn định. - Thước đo thực tế – Góc nhìn của phụ huynh mang đến một thước đo bên ngoài để kiểm chứng xem các chỉ số nội bộ có phản ánh đúng trải nghiệm thực tế của học sinh và gia đình hay không. Đạt được KPI này có nghĩa là LHBS xây dựng được danh tiếng là: “Ngôi trường nơi phụ huynh cảm thấy con mình trưởng thành về học thuật, nhân cách và sự tự tin qua từng năm học.”", "asp": "Duy trì mức độ hài lòng trên 90% từ năm 2026 trở đi.", "unit": "% (phần trăm phụ huynh hài lòng)", "method": "[Tỉ lệ % hài lòng chung của phụ huynh] = (([Số phụ huynh thể hiện sự hài lòng tiến bộ Học thuật] + [Số phụ huynh thể hiện sự hài lòng tiến bộ kĩ năng thế kỉ 21] + [Số phụ huynh thể hiện sự hài lòng tiến bộ Phát triển cá nhân])/([Số phụ huynh tham gia khảo sát về tiến bộ Học thuật] + [Số phụ huynh thể hiện sự hài lòng tiến bộ kĩ năng thế kỉ 21] + [Số phụ huynh tham gia khảo sát về tiến bộ Phát triển cá nhân]))*100", "split": "1. Cấp học (Mầm non, Tiểu học, THCS, THPT) 2. Khối lớp 3. Năm học 4. Lĩnh vực - (Học thuật, kĩ năng thế kỉ 21, Phát triển cá nhân) 5. Môn học", "collect": "Triển khai khảo sát phụ huynh định kì (online hoặc giấy). - Mỗi mục hỏi sử dụng thang đo Likert 5 mức: Rất không hài lòng – Không hài lòng – Bình thường – Hài lòng – Rất hài lòng. - Bộ phận M&E tổng hợp kết quả, phân loại theo từng chỉ số phụ.", "src": "Phiếu khảo sát phụ huynh (structured surveys). - Feedback từ kênh phản hồi chính thức (họp phụ huynh, kênh chăm sóc phụ huynh). - Hệ thống quản lí khảo sát/Google Forms/Survey tool.", "freq": "2 lần/năm: cuối học kì 1 và cuối năm học. - Báo cáo tổng hợp hằng năm để đưa vào KPI Scorecard.", "owner": "Chưa điền", "store": "Bộ phận M&E (dạng số trên hệ thống ISO 21001:2018 và bản cứng lưu trữ). - Dashboard KPI nội bộ.", "analyze": "Tính % phụ huynh hài lòng theo từng chỉ số phụ. - Tính % tổng thể (≥ Hài lòng). - So sánh kết quả theo năm để theo dõi xu hướng. - Phân tích bổ sung theo cấp học hoặc nhóm phụ huynh (nếu cần).", "present": "Biểu đồ cột theo từng chỉ số phụ. - Biểu đồ đường theo xu hướng qua các năm. - Dashboard hiển thị % hài lòng tổng thể và % từng lĩnh vực.", "verify": "Chưa điền", "report": "Báo cáo KPI định kì trong Institutional Scorecard. - Trình bày tại cuộc họp Ban Giám hiệu & Hội đồng Chiến lược. - Tóm tắt chia sẻ trong báo cáo thường niên với phụ huynh và đối tác.", "pts": [{"n": "1.1", "name": "Số phụ huynh tham gia khảo sát về tiến bộ Học thuật (Academic Competencies)", "desc": "Số phụ huynh phản hồi khảo sát/feedback hằng năm về tiến bộ học thuật (mẫu số để tính tỉ lệ)."}, {"n": "1.2", "name": "Số phụ huynh thể hiện sự hài lòng tiến bộ Học thuật (Academic Competencies) của học sinh", "desc": "Số phụ huynh tham gia khảo sát/feedback hằng năm thể hiện sự \"Hài lòng+\" về tiến bộ học thuật của học sinh."}, {"n": "1.3", "name": "Điểm hài lòng về tiến bộ Học thuật (Academic Competencies)", "desc": "([1.2]/[1.1])*100 Mức độ phụ huynh đánh giá hài lòng về kết quả học tập & kiến thức của con."}, {"n": "2.1", "name": "Số phụ huynh tham gia khảo sát về tiến bộ Kĩ năng / năng lực bổ trợ", "desc": "Số phụ huynh phản hồi khảo sát/feedback hằng năm về tiến bộ kĩ năng / năng lực bổ trợ (STEM, JA, AI Robotics)"}, {"n": "2.2", "name": "Số phụ huynh thể hiện sự hài lòng tiến bộ Kĩ năng / năng lực bổ trợ của học sinh", "desc": "Số phụ huynh tham gia khảo sát/feedback hằng năm thể hiện sự \"Hài lòng+\" về tiến bộ kĩ năng / năng lực bổ trợ của học sinh."}, {"n": "2.3", "name": "Điểm hài lòng về tiến bộ Kĩ năng / năng lực bổ trợ", "desc": "([2.2]/[2.1])*100 Mức độ phụ huynh đánh giá hài lòng về tiến bộ kĩ năng / năng lực bổ trợ của con."}, {"n": "3.1", "name": "Số phụ huynh tham gia khảo sát về tiến bộ Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21", "desc": "Số phụ huynh phản hồi khảo sát/feedback hằng năm về tiến bộ Phát triển cá nhân, Năng khiếu & Kĩ năng thế kỉ 21 (mẫu số để tính tỉ lệ)."}, {"n": "3.2", "name": "Số phụ huynh thể hiện sự hài lòng tiến bộ Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21 của học sinh", "desc": "Số phụ huynh tham gia khảo sát/feedback hằng năm thể hiện sự \"Hài lòng+\" về tiến bộ Phát triển cá nhân, Năng khiếu & Kĩ năng thế kỉ 21."}, {"n": "3.3", "name": "Điểm hài lòng về tiến bộ Phát triển cá nhân (Personal Growth Attributes), Năng khiếu & Kĩ năng thế kỉ 21", "desc": "([3.2]/[3.1])*100 Mức độ phụ huynh đánh giá hài lòng về tiến bộ Phát triển cá nhân, Năng khiếu & Kĩ năng thế kỉ 21 của con."}, {"n": "4", "name": "Tỉ lệ % hài lòng chung của phụ huynh", "desc": "((1.2]+[2.2]+[3.2])/([1.1]+[2.1]+[3.1]))*100 Tỉ lệ phụ huynh tham gia khảo sát nhận xét mức độ kết quả của con có đáp ứng kì vọng gia đình (chọn mức ≥ “Hài lòng” trong khảo sát)."}], "cut": ["31/12", "31/5"], "cutNote": "", "review": [], "out": "1.2"}, {"c": "2.1.1", "n": "Tăng ≥10% số lượng sáng kiến của giáo viên được công nhận so với năm trước", "def": "Chỉ số KPI này theo dõi số lượng dự án, chương trình hoặc đổi mới do giáo viên LHBS khởi xướng và được Sở Giáo dục & Đào tạo (DoET) công nhận chính thức mỗi năm. - “Công nhận” có thể bao gồm giải thưởng, chứng nhận hoặc bằng khen từ Sở GD&ĐT cho các sáng kiến trong thiết kế chương trình, phương pháp giảng dạy, hoạt động ngoại khóa hoặc gắn kết cộng đồng. - Ví dụ: Giáo viên thiết kế một mô-đun STEM sáng tạo, xây dựng chương trình song ngữ thành công, hoặc dẫn dắt một dự án phục vụ cộng đồng có tác động lớn.", "why": "Nâng tầm uy tín giảng dạy – Giáo viên được công nhận giúp LHBS trở thành trung tâm giáo dục xuất sắc tại Đồng Nai. - Tạo động lực cho đội ngũ – Giáo viên cảm thấy tự hào và được trân trọng khi ý tưởng của họ được các cơ quan uy tín ghi nhận. - Cải thiện việc học của học sinh – Sáng kiến của giáo viên trực tiếp nâng cao trải nghiệm học tập trong lớp học. - Xây dựng niềm tin với phụ huynh – Phụ huynh thấy rằng con em mình được học tập từ những nhà giáo được công nhận là xuất sắc trong lĩnh vực. Đạt được KPI này có nghĩa là LHBS được biết đến như: “Ngôi trường nơi giáo viên không chỉ giảng dạy – mà còn truyền cảm hứng bằng những sáng kiến được công nhận bởi các cơ quan giáo dục hàng đầu.”", "asp": "Ít nhất 10% giáo viên được công nhận hằng năm.", "unit": "% (tỉ lệ tăng trưởng năm sau so với năm trước)", "method": "[Mức tăng trưởng % sáng kiến được công nhận/trao giải bởi DoET] = ([Số sáng kiến được công nhận/trao giải bởi DoET năm nay] - [Số sáng kiến được công nhận/trao giải bởi DoET năm trước])/[Số sáng kiến được công nhận/trao giải bởi DoET năm trước])*100", "split": "1. Cấp học 2. Bộ môn/nhóm chuyên môn 3. Thâm niên công tác 4. Loại sáng kiến - Phương pháp Dạy học - Tập trung vào các sáng kiến liên quan đến phương pháp giảng dạy theo từng môn học. - Đổi mới Sáng tạo và Ứng dụng Công nghệ - Liên quan đến đổi mới trong dạy học, chuyển đổi số và hoạt động hướng nghiệp. - Giáo dục Phổ thông và Hòa nhập - Tập trung vào các lĩnh vực giáo dục nền tảng và giáo dục hòa nhập cho học sinh đặc thù. - Quản lí và Lãnh đạo Nhà trường - Bao gồm các hoạt động quản lí, điều hành và phát triển đội ngũ trong nhà trường. - Công tác Học sinh và Hỗ trợ Phát triển Toàn diện - Bao gồm các hoạt động hỗ trợ học sinh, tư tưởng chính trị, sức khỏe, và hướng nghiệp. - Quản lí Nguồn lực Dạy học - Tập trung vào các hoạt động hỗ trợ giảng dạy và học tập, đảm bảo chất lượng nguồn lực. 5. Cấp độ công nhận - Nội bộ trường (được trường công nhận, sau đó gửi đi). - Cấp Phường / Sở GD&ĐT cấp huyện/tỉnh (giấy chứng nhận, bằng khen). - Cấp quốc gia/khu vực (nếu có, ví dụ tham gia hội thi GV sáng tạo cấp Bộ GD&ĐT).", "collect": "Trường thống kê danh sách sáng kiến của GV hằng năm. - Lọc ra những sáng kiến chính thức gửi DoET và kết quả công nhận (có văn bản/bằng khen). - Đối chiếu số liệu năm nay với năm trước.", "src": "1. Trường thống kê danh sách sáng kiến của GV hằng năm. 2. Lọc ra những sáng kiến chính thức gửi DoET và kết quả công nhận (có văn bản/bằng khen). 3. Đối chiếu số liệu năm nay với năm trước.", "freq": "1 lần/năm, tổng hợp vào cuối năm học (hạn chót 31/7). - Cập nhật bổ sung ngay sau khi có sáng kiến của GV nhận được bằng khen.", "owner": "Chưa điền", "store": "Bộ phận Học vụ & M&E (bản cứng + bản mềm). - Hệ thống quản lí ISO 21001:2018.", "analyze": "Tính tổng số sáng kiến được công nhận trong năm. - So sánh với năm trước để ra mức tăng trưởng tuyệt đối và %. - Đánh giá mức đạt mục tiêu: nếu tăng trưởng ≥10% thì KPI đạt.", "present": "Biểu đồ cột: số sáng kiến được công nhận từng năm. - Biểu đồ đường: % tăng trưởng qua các năm. - Bảng tổng hợp: năm trước – năm nay – chênh lệch tuyệt đối – chênh lệch %.", "verify": "Chưa điền", "report": "Báo cáo KPI hằng năm trong Institutional Scorecard. - Trình bày trong họp Hội đồng Chiến lược & Ban Giám hiệu. - Đưa tóm tắt vào báo cáo thường niên (phần chất lượng giảng dạy & thành tích giáo viên).", "pts": [{"n": "1", "name": "Tổng số giáo viên toàn trường", "desc": "Tổng GV chính thức tại LHBS trong năm học (mẫu số để tính %)."}, {"n": "2", "name": "Số lượng sáng kiến/đề tài do GV đề xuất", "desc": "Tổng số sáng kiến giảng dạy, chương trình, hoặc dự án do GV khởi xướng (nộp lên trường hoặc DoET)."}, {"n": "3", "name": "Số sáng kiến được gửi thẩm định/đăng kí tại DoET", "desc": "Sáng kiến chính thức được trường gửi lên DoET xem xét, đánh giá."}, {"n": "4", "name": "Số sáng kiến được công nhận/trao giải bởi DoET", "desc": "Sáng kiến giảng dạy, chương trình, hoặc hoạt động cộng đồng được DoET cấp bằng khen, chứng nhận hoặc giải thưởng."}, {"n": "5", "name": "Số giáo viên có ít nhất một sáng kiến được công nhận (không trùng)", "desc": "Đếm số GV duy nhất được công nhận (tránh tính trùng khi một GV có nhiều sáng kiến)."}, {"n": "6", "name": "Tỉ lệ % GV có sáng kiến được công nhận", "desc": "([5]/[1])*100 Tỉ lệ phần trăm giáo viên trong toàn trường có ít nhất một sáng kiến giảng dạy, chương trình hoặc dự án được Sở GD&ĐT (DoET) chính thức công nhận trong năm học."}, {"n": "7", "name": "Mức tăng trưởng tuyệt đối – Số sáng kiến được công nhận/trao giải bởi DoET", "desc": "[4] năm nay - [4] năm trước Số lượng chênh lệch sáng kiến giáo viên được Sở GD&ĐT công nhận trong năm hiện tại so với năm trước."}, {"n": "8", "name": "Mức tăng trưởng % – Số sáng kiến được công nhận/trao giải bởi DoET", "desc": "([7]/[4] năm trước)*100 Tỉ lệ phần trăm tăng trưởng số sáng kiến giáo viên được Sở GD&ĐT công nhận trong năm hiện tại so với năm trước."}], "cut": ["31/7"], "cutNote": "", "review": [], "out": "2.1"}, {"c": "2.1.2", "n": "Tăng ≥5% số lượng dự án của học sinh đạt giải thưởng so với năm trước", "def": "Chỉ số KPI này theo dõi số lượng dự án do học sinh LHBS thực hiện và đạt giải thưởng ở cấp thành phố, tỉnh hoặc quốc gia trong các cuộc thi về học thuật, STEM, nghệ thuật, đổi mới sáng tạo và tác động xã hội. - Ghi nhận các dự án vượt ra ngoài yêu cầu lớp học – thể hiện tính sáng tạo, khả năng ứng dụng thực tiễn và kết quả đo lường được. - Bao gồm cả dự án cá nhân và nhóm, với sự công nhận từ các tổ chức hoặc cuộc thi uy tín.", "why": "Khẳng định chất lượng học tập – Các giải thưởng bên ngoài LHBS chứng minh rằng kỹ năng của học sinh đạt hoặc vượt chuẩn mực bên ngoài. - Xây dựng sự tự tin cho học sinh – Việc được công nhận khích lệ học sinh đặt mục tiêu cao hơn và chấp nhận những thử thách lớn hơn. - Nâng cao uy tín của trường – Việc liên tục đạt giải đưa LHBS trở thành cái tên nổi bật trong việc đào tạo tài năng trẻ. - Truyền cảm hứng văn hóa xuất sắc – Những sản phẩm đoạt giải trở thành hình mẫu để các học sinh khác noi theo. Đạt được KPI này có nghĩa là LHBS được tôn vinh là: “Ngôi trường nơi sự sáng tạo, đổi mới và nỗ lực của học sinh tỏa sáng vượt ra ngoài khuôn viên và vươn ra thế giới rộng lớn hơn.”", "asp": "Tăng tối thiểu 5% số lượng dự án đoạt giải mỗi năm so với năm trước.", "unit": "% (tỉ lệ tăng trưởng năm sau so với năm trước)", "method": "[Mức tăng trưởng dự án HS được công nhận/trao giải] = (([Số sáng kiến HS được công nhận/trao giải năm nay] - [Số sáng kiến HS được công nhận/trao giải năm trước])/[Số sáng kiến HS được công nhận/trao giải năm trước])*100", "split": "1. Cấp học 2. Khối lớp 3. Lĩnh vực - Dự án đơn môn (academic subjects). - STEM/Khoa học công nghệ (liên môn). - Nghệ thuật & sáng tạo. - Đổi mới & khởi nghiệp. - Tác động xã hội/cộng đồng. 5. Cấp độ giải thưởng - Các cơ sở giáo dục ngoài LHBS - Thành phố - Tỉnh/DoET - Quốc gia - Quốc tế (nếu có)", "collect": "Tổng hợp danh sách dự án HS nộp thi và đoạt giải từ giáo viên phụ trách & phòng Chuyên môn. - Đối chiếu kết quả chính thức từ BTC cuộc thi, Sở GD&ĐT hoặc tổ chức công nhận. - Loại trùng dữ liệu để tính số HS duy nhất có dự án đoạt giải.", "src": "Hồ sơ dự thi của HS (nội bộ trường). - Công văn, chứng nhận, kết quả trao giải từ DoET/các tổ chức uy tín. - Báo cáo từ giáo viên hướng dẫn.", "freq": "1 lần/năm, tổng hợp vào cuối năm học. - Cập nhật bổ sung ngay sau khi có dự án của HS nhận được giải thưởng.", "owner": "Chưa điền", "store": "Hệ thống lưu trữ dữ liệu trường (Google Drive/Phần mềm M&E), đồng bộ với phòng Chuyên môn và phòng Đào tạo.", "analyze": "So sánh số lượng & tỉ lệ HS đoạt giải theo năm. - Tính mức tăng trưởng tuyệt đối và %. - Phân tích theo lĩnh vực (STEM, nghệ thuật, học thuật, xã hội) và cấp độ (thành phố, tỉnh, quốc gia, quốc tế).", "present": "Bảng tổng hợp năm – năm. - Biểu đồ cột thể hiện số dự án đoạt giải qua các năm. - Biểu đồ tròn thể hiện phân bổ theo lĩnh vực/cấp độ.", "verify": "Chưa điền", "report": "Báo cáo thường niên gửi HĐ Chiến lược & Sở GD&ĐT. - Tích hợp trong Báo cáo Kết quả Năm học của LHBS. - Tóm lược thành KPI Dashboard (phục vụ nội bộ).", "pts": [{"n": "1", "name": "Tổng số học sinh toàn trường", "desc": "Tổng số HS đang theo học tại LHBS trong năm học, làm mẫu số để tính tỉ lệ tham gia."}, {"n": "2", "name": "Số lượng dự án/sáng kiến do HS thực hiện", "desc": "Tổng số dự án/sáng kiến học tập, nghiên cứu, sáng tạo do HS triển khai trong năm (bao gồm cả dự thi và không dự thi)."}, {"n": "3", "name": "Số dự án/sáng kiến HS được gửi dự thi", "desc": "Tổng số dự án/sáng kiến chính thức được nộp tham gia các cuộc thi/đánh giá bên ngoài LHBS."}, {"n": "4", "name": "Số dự án/sáng kiến HS được công nhận/trao giải", "desc": "Tổng số dự án/sáng kiến của HS được trao giải, bằng khen, hoặc chứng nhận từ các cấp (thành phố, tỉnh, quốc gia, quốc tế)."}, {"n": "5", "name": "Số HS có ít nhất một dự án/sáng kiến được công nhận/trao giải (không trùng)", "desc": "Số lượng học sinh duy nhất tham gia và có sản phẩm đoạt giải, không tính trùng lặp nhiều dự án/giải thưởng."}, {"n": "6", "name": "Số HS tham dự các kì thi HS giỏi (trong nước và quốc tế)", "desc": "Tổng số học sinh tham gia các kỳ thi học sinh giỏi cấp tỉnh, quốc gia hoặc quốc tế trong năm học."}, {"n": "7", "name": "Số HS đạt giải HS giỏi (trong nước và quốc tế)", "desc": "Tổng số học sinh đạt giải thưởng tại các kỳ thi học sinh giỏi cấp tỉnh, quốc gia hoặc quốc tế trong năm học."}, {"n": "8", "name": "Tỉ lệ % HS có dự án/sáng kiến được công nhận", "desc": "([5]/[1])*100 ([Số HS có ít nhất một dự án/sáng kiến đoạt giải]/[Tổng số HS toàn trường])*100 → Cho thấy mức độ lan tỏa và tác động của các giải thưởng tới cộng đồng HS."}, {"n": "9", "name": "Mức tăng trưởng tuyệt đối – Số dự án/sáng kiến HS được công nhận/trao giải", "desc": "[4] năm nay - [4] năm trước Số lượng chênh lệch dự án/sáng kiến của HS được công nhận/trao giải trong năm hiện tại so với năm trước."}, {"n": "10", "name": "Mức tăng trưởng % – Số dự án HS được công nhận/trao giải", "desc": "([9]/[4] năm trước)*100 Tỉ lệ phần trăm tăng trưởng số dự án/sáng kiến HS công nhận/trao giải trong năm hiện tại so với năm trước."}, {"n": "11", "name": "Mức tăng trưởng tuyệt đối – Số HS đạt giải HS giỏi (trong nước và quốc tế)", "desc": "[7] năm nay - [7] năm trước Số lượng học sinh đạt giải tăng thêm so với năm trước (tính bằng số học sinh)."}, {"n": "12", "name": "Mức tăng trưởng % – Số HS đạt giải HS giỏi (trong nước và quốc tế)", "desc": "([11]/[7] năm trước)*100 Tỉ lệ phần trăm tăng hoặc giảm số học sinh đạt giải so với năm trước."}], "cut": ["31/5"], "cutNote": "cuối năm học", "review": [], "out": "2.1"}, {"c": "2.2.1", "n": "Tăng cường trao đổi trong nước và quốc tế do LHBS tổ chức hằng năm", "def": "Chỉ số KPI này theo dõi tổng số chương trình trao đổi giáo viên và học sinh mà LHBS tổ chức hằng năm – bao gồm cả đối tác trong nước và quốc tế. - Bao gồm các chuyến thăm ngắn hạn, trao đổi dài hạn, hội thảo chung, và các dự án học thuật hoặc văn hóa hợp tác. - Bao quát trao đổi với các trường đối tác, đại học và tổ chức, nơi người tham gia được trải nghiệm môi trường học tập khác biệt và chia sẻ tri thức.", "why": "Mở rộng tầm nhìn – Các chương trình trao đổi mang lại trải nghiệm thực tế về những nền văn hóa, phong cách giảng dạy và thế giới quan khác nhau. - Củng cố tinh thần công dân toàn cầu – Học sinh và giáo viên phát triển sự đồng cảm, khả năng thích ứng và kỹ năng giao tiếp xuyên văn hóa. - Làm giàu văn hóa trường học – Người tham gia sau khi trở về mang theo ý tưởng, nguồn cảm hứng và các thực tiễn tốt để lan tỏa cho toàn cộng đồng. - Nâng cao vị thế LHBS – Việc tổ chức trao đổi khẳng định năng lực của nhà trường như một đối tác quốc tế đáng tin cậy. Đạt được KPI này có nghĩa là LHBS được biết đến như: “Một trung tâm năng động nơi thế giới gặp gỡ, học hỏi và cùng nhau phát triển.”", "asp": "Duy trì ít nhất 20 chương trình trao đổi mỗi năm với các chỉ số tác động tích cực từ người tham gia.", "unit": "Tổng số lượng HS, GV đối tác và các đối tác khác đến trao đổi với LHBS (số người tham gia).", "method": "Tổng hợp số chương trình trao đổi do LHBS đăng cai (domestic + international). - Đếm số lượng HS, GV LHBS tham gia; số HS, GV đối tác tham gia; số đối tác khác tham gia.", "split": "1. Cấp học 2. Khối lớp 3. Loại trao đổi: trong nước / quốc tế. 4. Nhóm tham gia: HS LHBS / GV LHBS / HS đối tác / GV đối tác / Đối tác khác.", "collect": "Ghi nhận danh sách tham dự từ Ban tổ chức chương trình. - Thu thập báo cáo từ GV phụ trách và phòng Quan hệ Đối ngoại. - Phát phiếu khảo sát hài lòng cho tất cả người tham gia ngay sau chương trình.", "src": "Hồ sơ chương trình (agenda, danh sách khách mời, danh sách HS/GV tham dự). - Báo cáo tổng kết từ Ban tổ chức. - Phiếu khảo sát hài lòng (Google Form/giấy).", "freq": "Mỗi chương trình trao đổi; tổng hợp và báo cáo vào cuối học kì & cuối năm học.", "owner": "Chưa điền", "store": "Hệ thống dữ liệu nội bộ (Google Drive/School Management System), quản lí bởi phòng Quan hệ Đối ngoại & M&E.", "analyze": "Thống kê số lượng theo từng nhóm tham gia & loại trao đổi. - So sánh số lượng và % tăng trưởng theo năm. - Phân tích mức độ hài lòng trung bình & các điểm cần cải thiện.", "present": "Bảng tổng hợp (domestic vs international). - Biểu đồ cột (số chương trình, số người tham gia). - Biểu đồ tròn (cơ cấu người tham gia). - Biểu đồ đường (xu hướng tăng trưởng theo năm).", "verify": "Chưa điền", "report": "Báo cáo học kì và báo cáo năm học gửi Ban Giám hiệu & Ban Chiến lược. - Lồng ghép trong báo cáo KPI toàn trường. - Tóm lược bằng dashboard trực quan cho nội bộ (Ban Chiến lược & BGH).", "pts": [{"n": "1.1", "name": "Số chương trình trao đổi trong nước do LHBS đăng cai", "desc": "Tổng số hoạt động trao đổi với đối tác trong nước (workshop, tham quan, giao lưu) được tổ chức tại LHBS."}, {"n": "1.2", "name": "Số lượng học sinh LHBS tham gia trao đổi trong nước", "desc": "Tổng số HS của LHBS trực tiếp tham gia vào các chương trình trao đổi với đối tác trong nước."}, {"n": "1.3", "name": "Số lượng giáo viên LHBS tham gia trao đổi trong nước", "desc": "Tổng số GV/nhân viên LHBS trực tiếp tham gia, giảng dạy hoặc hỗ trợ chương trình trao đổi với đối tác trong nước."}, {"n": "1.4", "name": "Số lượng học sinh đối tác tham gia trao đổi trong nước", "desc": "Tổng số HS từ các trường/đơn vị đối tác trong nước đến LHBS tham gia chương trình."}, {"n": "1.5", "name": "Số lượng giáo viên đối tác tham gia trao đổi trong nước", "desc": "Tổng số GV từ trường/đơn vị đối tác trong nước đến LHBS tham gia chương trình."}, {"n": "1.6", "name": "Số lượng đối tác khác (không phải giáo viên và học sinh) tham gia trao đổi trong nước", "desc": "Tổng số khách mời, chuyên gia, cán bộ tổ chức trong nước tham gia chương trình tại LHBS."}, {"n": "1.7", "name": "Mức độ hài lòng của người tham gia trao đổi trong nước (%)", "desc": "Tỉ lệ % người tham gia (HS, GV, đối tác khác) đánh giá hài lòng về chương trình trao đổi trong nước tại LHBS."}, {"n": "2.1", "name": "Số chương trình trao đổi quốc tế do LHBS đăng cai", "desc": "Tổng số hoạt động trao đổi với đối tác quốc tế (văn hóa, học thuật, chuyên môn) được tổ chức tại LHBS."}, {"n": "2.2", "name": "Số lượng học sinh LHBS tham gia trao đổi quốc tế", "desc": "Tổng số HS của LHBS trực tiếp tham gia chương trình trao đổi với đối tác quốc tế."}, {"n": "2.3", "name": "Số lượng giáo viên LHBS tham gia trao đổi quốc tế", "desc": "Tổng số GV/nhân viên LHBS tham gia, giảng dạy hoặc hỗ trợ chương trình trao đổi với đối tác quốc tế."}, {"n": "2.4", "name": "Số lượng học sinh đối tác tham gia trao đổi quốc tế", "desc": "Tổng số HS từ trường/đơn vị quốc tế đến LHBS tham gia chương trình."}, {"n": "2.5", "name": "Số lượng giáo viên đối tác tham gia trao đổi quốc tế", "desc": "Tổng số GV từ trường/đơn vị quốc tế đến LHBS tham gia chương trình."}, {"n": "2.6", "name": "Số lượng đối tác khác (không phải giáo viên và học sinh) tham gia trao đổi quốc tế", "desc": "Tổng số khách mời, chuyên gia, cán bộ quốc tế tham gia chương trình tại LHBS."}, {"n": "2.7", "name": "Mức độ hài lòng của người tham gia trao đổi quốc tế (%)", "desc": "Tỉ lệ % người tham gia (HS, GV, đối tác quốc tế khác) đánh giá hài lòng về chương trình trao đổi quốc tế tại LHBS."}, {"n": "3", "name": "Tổng số chương trình trao đổi (domestic + international)", "desc": "[1.1]+[2.1] Tổng hợp số chương trình trao đổi do LHBS đăng cai trong nước và quốc tế."}, {"n": "4", "name": "Tổng số học sinh LHBS tham gia chương trình trao đổi (domestic + international)", "desc": "[1.2]+[2.2] Tổng số lượt HS LHBS tham gia chương trình trao đổi trong năm."}, {"n": "5", "name": "Tổng số giáo viên LHBS tham gia chương trình trao đổi (domestic + international)", "desc": "[1.3]+[2.3] Tổng số lượt GV/nhân viên LHBS tham gia chương trình trao đổi trong năm."}, {"n": "6", "name": "Tổng số học sinh đối tác tham gia chương trình trao đổi (domestic + international)", "desc": "[1.4]+[2.4] Tổng số lượt HS đối tác (trong nước + quốc tế) đến LHBS tham gia chương trình."}, {"n": "7", "name": "Tổng số giáo viên đối tác tham gia chương trình trao đổi (domestic + international)", "desc": "[1.5]+[2.5] Tổng số lượt GV đối tác (trong nước + quốc tế) đến LHBS tham gia chương trình."}, {"n": "8", "name": "Tổng đối tác khác (không phải giáo viên và học sinh) tham gia trao đổi (domestic + international)", "desc": "[1.6]+[2.6] Tổng số lượt đối tác khác (chuyên gia, cán bộ tổ chức, khách mời) tham gia trao đổi tại LHBS."}, {"n": "9", "name": "Mức độ hài lòng của người tham gia trao đổi trong năm (%)", "desc": "Điểm trung bình/ tỉ lệ % hài lòng của tất cả người tham gia (HS, GV, đối tác khác) đối với các chương trình trao đổi do LHBS đăng cai trong năm."}], "cut": ["31/12", "31/5"], "cutNote": "cuối học kỳ và cuối năm học", "review": [], "out": "2.2"}, {"c": "2.2.2", "n": "Tăng trưởng quan hệ đối tác học thuật và doanh nghiệp trong Liên minh STEM ≥10% vào năm 2030", "def": "Chỉ số KPI này đo lường tỷ lệ các cơ sở giáo dục tại tỉnh Đồng Nai – từ bậc phổ thông (K–12) đến cao đẳng & đại học – tham gia tích cực vào Liên minh STEM do LHBS dẫn dắt. - “Tham gia tích cực” không chỉ là đăng kí tham gia, mà còn bao gồm việc đóng góp nguồn lực, đồng tổ chức sự kiện, triển khai các chương trình STEM chung hoặc tham gia vào hoạt động hoạch định của Liên minh. - Bao gồm cả hợp tác với các cơ sở giáo dục và doanh nghiệp trong lĩnh vực STEM nhằm mang lại các ứng dụng thực tiễn cho người học. KPI tập trung vào tăng trưởng thành viên và mức độ tham gia thực chất, không chỉ kí kết trên giấy, và dùng “mức độ tham gia thực chất” như tiêu chí xếp hạng đối tác: - Cấp 1: kí kết, chưa hoạt động - Cấp 2: Tham gia ≥1 hoạt động/năm (sự kiện, cuộc thi, hội thảo, đào tạo, dự án đồng hành) trong năm học. - Cấp 3: Đồng tổ chức hoặc chủ trì cùng LHBS ít nhất 01 hoạt động trong năm học.", "why": "Mở rộng cơ hội – Nhiều đối tác hơn đồng nghĩa với nhiều cuộc thi, chương trình cố vấn, hội thảo và cơ hội thực tập hơn cho học sinh LHBS. - Khuếch đại tác động – Một mạng lưới hợp tác mạnh mẽ mang lại lợi ích không chỉ cho học sinh LHBS mà còn cho toàn bộ hệ sinh thái giáo dục STEM của tỉnh Đồng Nai. - Định vị LHBS là đơn vị tiên phong – Vai trò điều phối một sáng kiến tầm cỡ toàn tỉnh giúp củng cố vị thế của LHBS như một nhà đổi mới và có tầm ảnh hưởng trong giáo dục. - Thúc đẩy tính bền vững – Quan hệ đối tác đa dạng tạo ra dòng chảy ổn định về nguồn lực, chuyên môn và sự lan tỏa cho các sáng kiến STEM. Đạt được KPI này có nghĩa là LHBS sẽ được công nhận là: “Trái tim của giáo dục STEM tại Đồng Nai – nơi nhà trường, doanh nghiệp và đổi mới sáng tạo cùng hội tụ vì tương lai.”", "asp": "Đạt tỷ lệ 10% các cơ sở giáo dục trong tỉnh tham gia tích cực vào Liên minh STEM trước năm 2030.", "unit": "Số lượng và % (phần trăm)", "method": "1. Tỉ lệ cơ sở giáo dục tỉnh là thành viên liên minh [Tỉ lệ cơ sở giáo dục tỉnh là thành viên liên minh] = ([Tổng số cơ sở giáo dục là thành viên liên minh STEM]/[Tổng số cơ sở giáo dục trong tỉnh])*100 2. Mức tăng trưởng % số đối tác liên minh (giáo dục + doanh nghiệp) [Tỉ lệ tăng trưởng đối tác giáo dục + doanh nghiệp] = ([Số đối tác giáo dục + doanh nghiệp năm nay] - [Số đối tác giáo dục + doanh nghiệp năm trước])/([Số đối tác giáo dục + doanh nghiệp năm trước]))*100 3. Mức tăng trưởng % số thành viên hoạt động tích cực [Tỉ lệ tăng trưởng đối tác giáo dục + doanh nghiệp hoạt động tích cực] = ([Số đối tác giáo dục + doanh nghiệp hoạt động tích cực năm nay] - [Số đối tác giáo dục + doanh nghiệp hoạt động tích cực năm trước])/([Số đối tác giáo dục + doanh nghiệp hoạt động tích cực năm trước]))*100", "split": "1. Theo loại đối tác - Cơ sở giáo dục / Doanh nghiệp / Tổ chức khoa học - công nghệ / Cơ quan quản lí. 2. Theo cấp độ hoạt động - Cấp 1 (ký kết, không tham gia), Cấp 2 (tham gia) / Cấp 3 (đồng tổ chức). 3. Theo địa bàn - Trong tỉnh / Ngoài tỉnh. 4. Theo lĩnh vực hợp tác - STEM, hướng nghiệp, đổi mới sáng tạo, nghiên cứu - công nghệ.", "collect": "Cập nhật danh sách thành viên Liên minh STEM (Master Member List) hằng năm. - Ghi nhận minh chứng hoạt động (attendance sheet, MoU, thư mời, biên bản hợp tác, poster, hình ảnh sự kiện). - Tổng hợp báo cáo hoạt động từ các phòng ban liên quan (Phòng Quan hệ Đối ngoại, Phòng Chuyên môn, Phòng STEM). - Khảo sát mức độ hài lòng của các thành viên hoạt động tích cực (Cấp 2 & 3) sau từng sự kiện hoặc định kì cuối năm.", "src": "Hồ sơ hoạt động Liên minh STEM (các chương trình, workshop, cuộc thi, sự kiện, đào tạo, dự án). - Biên bản hợp tác và danh sách đối tác tham dự. - Báo cáo tổng kết hoạt động Liên minh STEM. - Phiếu khảo sát hài lòng đối tác.", "freq": "Cập nhật định kì 2 lần/năm (giữa năm học và cuối năm học). - Tổng hợp & đối chiếu dữ liệu cuối năm học (tháng 6).", "owner": "Chưa điền", "store": "Thư mục “STEM Alliance Data Repository” trên hệ thống nội bộ (Google Drive/Smartsheet). - Đồng quản lí bởi Phòng Quan hệ Đối ngoại và Phòng M&E.", "analyze": "So sánh số lượng và tỉ lệ thành viên qua các năm. - So sánh số lượng và tỉ lệ thành viên hoạt động tích cực qua các năm. - Phân loại thành viên theo cấp độ hoạt động (Cấp 2 & Cấp 3). - Tính tốc độ tăng trưởng tuyệt đối và %. - Phân tích mức độ hài lòng và lĩnh vực hợp tác để đánh giá chất lượng kết nối.", "present": "Bảng tổng hợp theo năm và theo cấp độ hoạt động. - Biểu đồ đường thể hiện xu hướng tăng trưởng số thành viên hoạt động tích cực. - Biểu đồ cột so sánh theo loại đối tác và lĩnh vực hợp tác. - Biểu đồ tròn thể hiện cơ cấu Cấp 2 / Cấp 3.", "verify": "Chưa điền", "report": "Báo cáo hằng năm tích hợp trong Báo cáo Kết quả Năm học LHBS. - Báo cáo riêng về “Tác động Liên minh STEM Đồng Nai” gửi Sở GD&ĐT và đối tác chiến lược. - Tóm lược dữ liệu chính trên KPI Dashboard nội bộ (Smartsheet/Power BI).", "pts": [{"n": "1.1", "name": "Tổng số cơ sở giáo dục trong tỉnh (mẫu gốc)", "desc": "Tổng số trường K–12, cao đẳng, đại học trong địa bàn tỉnh Đồng Nai (do Sở GD&ĐT công bố) – dùng làm mẫu tính tỉ lệ tham gia."}, {"n": "1.2", "name": "Tổng số cơ sở giáo dục là thành viên liên minh STEM (tính đến cuối năm)", "desc": "Số trường K–12, cao đẳng, đại học đã chính thức tham gia Liên minh STEM do LHBS dẫn dắt."}, {"n": "1.3", "name": "Tổng số doanh nghiệp/đối tác STEM là thành viên liên minh", "desc": "Số doanh nghiệp hoặc tổ chức STEM đã chính thức tham gia hoặc kí kết hợp tác trong khuôn khổ Liên minh STEM."}, {"n": "2.1", "name": "Số sự kiện/chương trình STEM liên minh tổ chức hằng năm", "desc": "Tổng số hoạt động chung (cuộc thi, workshop, ngày hội STEM, tọa đàm, v.v.) có sự tham gia của các thành viên liên minh."}, {"n": "2.2", "name": "Số chương trình hợp tác đồng tổ chức (co-hosted) với thành viên Liên minh", "desc": "Số hoạt động được LHBS cùng các đối tác đồng tổ chức, minh chứng cho sự hợp tác hai chiều."}, {"n": "2.3", "name": "Số đối tác giáo dục tham gia hoạt động thực chất với LHBS trong năm (thành viên cấp 2 & 3)", "desc": "Số trường trong liên minh có tham gia ít nhất một hoạt động chung như workshop, cuộc thi, đào tạo, hoặc dự án STEM trong năm."}, {"n": "2.4", "name": "Số đối tác doanh nghiệp tham gia hoạt động thực chất với LHBS trong năm (thành viên cấp 2 & 3)", "desc": "Số doanh nghiệp hoặc tổ chức STEM có đóng góp thực tế (hỗ trợ chuyên gia, tài trợ, tổ chức thực hành, hoặc hướng dẫn nghề nghiệp)."}, {"n": "3", "name": "Tỉ lệ % cơ sở giáo dục trong tỉnh tham gia liên minh STEM", "desc": "([1.2]/[1.1])/*100 Tỉ lệ cơ sở giáo dục thành viên liên minh trên tổng số cơ sở giáo dục trong tỉnh"}, {"n": "4", "name": "Mức tăng trưởng tuyệt đối số đối tác liên minh (giáo dục + doanh nghiệp)", "desc": "([1.2] năm nay +[1.3] năm nay) - ([1.2] năm trước + [1.3] năm trước) Chênh lệch số đối tác thành viên liên minh năm nay so với năm trước."}, {"n": "5", "name": "Mức tăng trưởng % số đối tác liên minh (giáo dục + doanh nghiệp)", "desc": "([4]/([1.2] năm trước + [1.3] năm trước))*100 ([Số đối tác năm nay] - [Số đối tác năm trước])/([Số đối tác năm trước]))*100"}, {"n": "6", "name": "Mức tăng trưởng tuyệt đối – Thành viên hoạt động tích cực", "desc": "([2.3] năm nay +[2.4] năm nay) - ([2.3] năm trước + [2.4] năm trước) Chênh lệch số thành viên hoạt động tích cực so với năm trước."}, {"n": "7", "name": "Mức tăng trưởng % – Thành viên hoạt động tích cực", "desc": "([5]/([2.3] năm trước + [2.4] năm trước))*100 ([Số đối tác tích cực năm nay] - [Số đối tác tích cực năm trước])/([Số đối tác tích cực năm trước]))*100."}, {"n": "8", "name": "Mức độ hài lòng của thành viên liên minh (%)", "desc": "Tỉ lệ % thành viên (Cấp 2 & 3) đánh giá hài lòng với cơ hội hợp tác và giá trị từ Liên minh STEM."}], "cut": ["31/12", "30/6"], "cutNote": "", "review": [], "out": "2.2"}, {"c": "3.1.1", "n": "Triển khai hệ thống quản lí chất lượng quốc tế và đạt chứng nhận ISO 21001:2018", "def": "Chỉ số KPI này theo dõi hành trình của LHBS từ giai đoạn lập kế hoạch đến khi đạt chứng nhận ISO 21001:2018 hoàn chỉnh, bao gồm: - Xây dựng chính sách và qui trình đảm bảo chất lượng. - Đào tạo và tuân thủ của cán bộ, giáo viên và nhân viên ở tất cả các phòng ban. - Đánh giá nội bộ và kiểm tra mức độ sẵn sàng trước khi tiến hành đánh giá chính thức. - Đạt chứng nhận thành công từ tổ chức kiểm định độc lập được công nhận quốc tế. KPI này giám sát tiến độ và mức độ hoàn thành của LHBS so với toàn bộ các giai đoạn trong qui trình xây dựng, đánh giá và đạt chứng nhận ISO 21001:2018 - từ khâu lập kế hoạch, ban hành qui trình, đánh giá nội bộ, đến khi nhận chứng chỉ chính thức. Chỉ số này còn đo lường mức độ LHBS hoàn thành các hành động khắc phục (Corrective Actions) được nêu ra trong đánh giá nội bộ (Internal Audit) và đánh giá bên ngoài (Stage 1, Stage 2, hoặc Surveillance Audit) - mục tiêu là đảm bảo mọi điểm không phù hợp (non-conformities) hoặc khuyến nghị cải tiến đều được xử lí và đóng đúng hạn, theo yêu cầu của tiêu chuẩn ISO 21001:2018.", "why": "Đảm bảo niềm tin – Phụ huynh, đối tác và các bên liên quan có thể tin tưởng rằng LHBS vận hành theo chuẩn mực được quốc tế công nhận. - Thúc đẩy sự xuất sắc – Tạo ra khung quản lí giúp mọi qui trình – từ giảng dạy đến hành chính – được rà soát và cải tiến thường xuyên. - Hỗ trợ phát triển – Một hệ thống chất lượng vững mạnh giúp LHBS mở rộng qui mô hoạt động mà vẫn duy trì tiêu chuẩn cao. - Xây dựng niềm tự hào – Giáo viên, học sinh và phụ huynh có thể tự hào rằng mình là một phần của ngôi trường đạt chuẩn quốc tế. Đạt được KPI này có nghĩa là LHBS là: “Ngôi trường không chỉ cam kết về chất lượng – mà chứng minh điều đó mỗi ngày.”", "asp": "Hoàn tất chứng nhận ISO 21001:2018 trước cuối năm 2026.", "unit": "Trạng thái / % tiến độ theo giai đoạn kiểm định", "method": "1. Giai đoạn tiến độ: theo dõi mức độ hoàn thành từng bước của các giai đoạn trong qui trình xây dựng, đánh giá và đạt chứng nhận ISO 21001:2018 — từ khâu lập kế hoạch, ban hành qui trình, đánh giá nội bộ, đến khi nhận chứng chỉ chính thức. 2. Tỉ lệ hoàn thành hành động khắc phục (Audit Actions Completion %): [Tỉ lệ hành động khắc phục đã hoàn tất] = ([Số hành động khắc phục đã hoàn tất] / [Tổng số hành động khắc phục được nêu tra trong báo cáo đánh giá nội bộ hoặc đánh giá chứng nhận/giám sát])*100", "split": "1. Nguồn audit - (a) Đánh giá nội bộ, (b) Stage 1, (c) Stage 2, (d) Surveillance. 2. Theo phòng ban chịu trách nhiệm 3. Mức độ nghiêm trọng của lỗi - minor nonconformity, major nonconformity, observation. 4. Theo trạng thái tiến độ - hoàn tất / đang thực hiện / quá hạn", "collect": "Tổng hợp tất cả biên bản và báo cáo đánh giá (Internal & External Audit Reports). - Lập danh mục hành động khắc phục (Corrective Action Log) ghi rõ: mã số, đơn vị phụ trách, ngày phát hành, hạn hoàn thành, trạng thái. - Cập nhật định kì tiến độ thực hiện và trạng thái đóng của từng hành động. - Xác nhận hoàn tất hành động khắc phục bằng minh chứng (evidence) và chữ kí xác nhận của đơn vị audit hoặc QMR.", "src": "Báo cáo đánh giá nội bộ (Internal Audit Report) - Báo cáo đánh giá chứng nhận (Stage 1 & Stage 2 Audit Reports) - Báo cáo giám sát định kì (Surveillance Audit Reports) - Nhật kí hành động khắc phục (Corrective Action Register) - Biên bản họp xem xét của lãnh đạo (Management Review Minutes)", "freq": "2 lần/năm: Giữa năm học (sau đánh giá nội bộ) & cuối năm học (sau đánh giá chứng nhận hoặc giám sát) - Báo cáo tổng hợp hằng năm: tháng 6.", "owner": "Chưa điền", "store": "Thư mục “ISO 21001 Data Repository” trên hệ thống nội bộ (Google Drive / Smartsheet). - Lưu giữ bản cứng tại Phòng Đảm bảo Chất lượng (QA Office).", "analyze": "So sánh tiến độ thực tế với timeline của ISO. - Tính % hoàn thành hành động khắc phục theo từng đợt audit và tổng hợp hằng năm. - Phân tích nguyên nhân các hành động chậm tiến độ hoặc chưa đóng. - Đánh giá theo phòng ban để xác định đơn vị có điểm yếu trong việc tuân thủ ISO. - Theo dõi xu hướng cải tiến qua các kì audit liên tiếp.", "present": "Dashboard ISO: Biểu đồ progress bar thể hiện % hoàn thành hành động khắc phục (so với mục tiêu ≥95%). - Biểu đồ cột: So sánh giữa hành động nội bộ và bên ngoài. - Biểu đồ tròn: Cơ cấu Major/Minor/Observation. - Bảng chi tiết: liệt kê hành động chưa hoàn tất và phòng ban chịu trách nhiệm.", "verify": "Chưa điền", "report": "Báo cáo ngắn gọn trong Báo cáo Kết quả Năm học và Báo cáo Duy trì Hệ thống ISO 21001:2018. - Cập nhật định kì trên KPI Dashboard nội bộ (Smartsheet/Power BI). - Báo cáo chi tiết cho Hội đồng Chiến lược và đơn vị chứng nhận trong các kì giám sát.", "pts": [{"n": "1.1", "name": "Lựa chọn đơn vị tư vấn và chứng nhận ISO 21001:2018", "desc": "Xác định tổ chức tư vấn/đánh giá được công nhận (VD: BSI, SGS, QUACERT, TUV) để đồng hành trong quá trình xây dựng và chứng nhận hệ thống quản lí chất lượng giáo dục."}, {"n": "1.2", "name": "Thành lập Ban ISO & nhóm chuyên trách triển khai hệ thống", "desc": "Thành lập Ban chỉ đạo ISO 21001:2018 gồm đại diện BGH, các phòng ban và tổ chuyên môn để điều phối, giám sát tiến độ thực hiện."}, {"n": "1.3", "name": "Hoàn thiện sơ đồ qui trình & phạm vi áp dụng ISO 21001:2018", "desc": "Xác định phạm vi chứng nhận (cấp học, bộ phận, hoạt động được áp dụng ISO), lập sơ đồ qui trình chính và qui trình hỗ trợ."}, {"n": "1.4", "name": "Hoàn thành xây dựng chính sách chất lượng & mục tiêu chất lượng", "desc": "Ban hành Chính sách chất lượng, Mục tiêu chất lượng (Quality Policy & Objectives) theo yêu cầu của tiêu chuẩn ISO 21001:2018."}, {"n": "1.5", "name": "Đào tạo & truyền thông nội bộ về hệ thống ISO", "desc": "Tổ chức đào tạo, truyền thông nâng cao nhận thức cho giáo viên, nhân viên về hệ thống quản lí chất lượng ISO."}, {"n": "1.6", "name": "Ban hành & áp dụng qui trình/hồ sơ ISO trong toàn trường", "desc": "Chính thức đưa các qui trình, biểu mẫu và hướng dẫn công việc theo ISO vào vận hành thực tế trong các bộ phận."}, {"n": "1.7", "name": "Hoàn thành đánh giá nội bộ (Internal Audit)", "desc": "Tiến hành đánh giá nội bộ để kiểm tra mức độ tuân thủ và hiệu lực của hệ thống ISO trước khi đánh giá chính thức."}, {"n": "1.8", "name": "Thực hiện họp xem xét của lãnh đạo (Management Review)", "desc": "Ban Giám hiệu thực hiện họp định kì để xem xét kết quả đánh giá nội bộ, khuyến nghị cải tiến, và quiết định hành động khắc phục."}, {"n": "1.9", "name": "Hoàn tất khắc phục & cải tiến sau đánh giá nội bộ", "desc": "Hoàn thiện các hành động khắc phục, điều chỉnh qui trình, và đảm bảo sẵn sàng cho đánh giá chứng nhận chính thức."}, {"n": "1.1", "name": "Thực hiện Đánh giá chứng nhận giai đoạn 1 (Stage 1 Audit)", "desc": "Tổ chức chứng nhận đánh giá hồ sơ, qui trình và mức độ sẵn sàng của LHBS."}, {"n": "1.11", "name": "Thực hiện Đánh giá chứng nhận giai đoạn 2 (Stage 2 Audit)", "desc": "Đoàn chuyên gia đánh giá toàn bộ hệ thống tại hiện trường, phỏng vấn nhân sự, và xem xét tuân thủ thực tế."}, {"n": "1.12", "name": "Kết quả đánh giá chứng nhận ISO 21001:2018", "desc": "Kết luận của tổ chức chứng nhận – đạt/đạt có điều kiện/không đạt."}, {"n": "1.13", "name": "Nhận chứng chỉ ISO 21001:2018 chính thức", "desc": "LHBS được cấp chứng chỉ ISO 21001:2018 từ tổ chức chứng nhận được công nhận quốc tế."}, {"n": "1.14", "name": "Thời hạn hiệu lực chứng chỉ ISO", "desc": "Số năm hiệu lực chứng nhận (thường 3 năm), được ghi rõ trên chứng chỉ."}, {"n": "1.16", "name": "Duy trì & đánh giá giám sát định kì (Surveillance Audit)", "desc": "Thực hiện các đợt đánh giá giám sát hằng năm để đảm bảo hệ thống tiếp tục duy trì hiệu lực và cải tiến liên tục."}, {"n": "2.1", "name": "Tổng số hành động khắc phục được nêu ra", "desc": "Tổng hợp từ báo cáo đánh giá nội bộ hoặc đánh giá chứng nhận/giám sát."}, {"n": "2.2", "name": "Số hành động khắc phục đã hoàn tất", "desc": "Hành động đã triển khai và được xác nhận đóng bởi đơn vị audit."}, {"n": "2.3", "name": "Số hành động đang thực hiện", "desc": "Đang được triển khai nhưng chưa hoàn tất hoặc chờ xác nhận hiệu quả."}, {"n": "2.4", "name": "Số hành động quá hạn", "desc": "Đã đến hạn nhưng chưa thực hiện hoặc chưa xác nhận hoàn tất."}, {"n": "3", "name": "Tỉ lệ hoàn thành hành động khắc phục (Audit Actions Completion %)", "desc": "([2.2]/[2.1])*100 Tỉ lệ hành động khắc phục đã hoàn tất trên tổng số hành động khắc phục được nêu tra trong báo cáo đánh giá nội bộ hoặc đánh giá chứng nhận/giám sát."}], "cut": ["31/12", "30/6"], "cutNote": "", "review": [], "out": "3.1"}, {"c": "3.2.1", "n": "Tăng trưởng Doanh thu từ các Câu lạc bộ STEM, Robotics AI, Lập trình và Khoa học", "def": "Chỉ số KPI này theo dõi tổng doanh thu tích lũy tạo ra từ các chương trình ngoại khóa định hướng đổi mới sáng tạo của LHBS, bao gồm: - Câu lạc bộ STEM và các hoạt động sáng chế (maker activities). - Các khóa học Robotics AI và lập trình. - Câu lạc bộ khoa học, các cuộc thi và triển lãm. Doanh thu bao gồm học phí, tài trợ, phí tham gia sự kiện và đóng góp từ các đối tác.", "why": "Duy trì đổi mới – Doanh thu từ các chương trình này được tái đầu tư vào phòng thí nghiệm, trang thiết bị và phát triển năng lực giáo viên. - Nâng cao kỹ năng học sinh – Các hoạt động ngoại khóa chất lượng cao giúp học sinh LHBS phát triển tư duy phản biện, sáng tạo và khả năng ứng dụng thực tế. - Khẳng định giá trị thị trường – Nhu cầu tăng cho thấy sức hút thương hiệu và tính thiết thực của chương trình giáo dục LHBS. - Khuyến khích sáng kiến của đội ngũ – Giáo viên và người phụ trách chương trình thấy được phần thưởng cụ thể cho sự đổi mới của mình. Đạt được KPI này có nghĩa là LHBS trở thành: “Nơi trí tò mò được chuyển hóa thành đổi mới – và đổi mới trở thành động lực cho học tập và phát triển bền vững.”", "asp": "Đạt doanh thu tích lũy 1.000.000 USD vào năm 2030.", "unit": "USD hoặc VND (doanh thu gộp lũy kế từ tất cả CLB và chương trình KH–CN).", "method": "1. [Tổng doanh thu lũy kế] = Tổng doanh thu từ tất cả CLB (STEM, Robotics & AI, Lập trình, Khoa học) và các cuộc thi/triển lãm KH–CN qua các năm. 2. [Tỉ lệ tăng trưởng doanh thu hàng năm (%)] = (([Doanh thu năm nay] – [Doanh thu năm trước]) / [Doanh thu năm trước])*100. 3. [Tổng doanh thu mục tiêu đến 2030] = Cộng dồn tất cả doanh thu hằng năm từ 2025–2030.", "split": "1. Theo CLB/Chương trình: STEM, Robotics & AI, Lập trình, Khoa học. 2. Theo loại hình sự kiện: Cuộc thi, triển lãm, workshop, khóa học, hoạt động đối tác. 3 Theo nguồn thu: học phí, tài trợ, hợp tác doanh nghiệp, bán vé sự kiện. 4 Theo đối tượng tham gia: học sinh LHBS, học sinh ngoài trường, doanh nghiệp, tổ chức học thuật.", "collect": "Dữ liệu được tổng hợp định kì từ báo cáo tài chính nội bộ và báo cáo hoạt động CLB. Mỗi CLB và sự kiện KH–CN cập nhật bảng theo dõi doanh thu – chi phí – số người tham gia theo mẫu thống nhất. Dữ liệu sau đó được nhập vào hệ thống quản lí tài chính/Smartsheet của LHBS để tổng hợp lũy kế toàn trường.", "src": "Báo cáo tài chính từ Phòng Kế toán & Tài chính. - Báo cáo hoạt động từ các CLB STEM, Robotics & AI, Lập trình, Khoa học. - Báo cáo tài trợ & hợp tác từ Phòng Quan hệ đối ngoại. - Biểu mẫu thống kê học sinh tham gia và khảo sát hài lòng.", "freq": "Thu thập hàng quý (tổng hợp sơ bộ) và cuối năm học (tổng hợp chính thức). Báo cáo lũy kế cập nhật vào cuối năm tài chính hoặc học kì 2.", "owner": "Chưa điền", "store": "Hệ thống quản lí tài chính nội bộ LHBS (Google Drive/Smartsheet) do Phòng Kế toán & Tài chính lưu trữ và cập nhật định kì.", "analyze": "Phân tích xu hướng tăng trưởng doanh thu và số lượng học sinh tham gia theo từng năm. - Tính tỉ lệ tăng trưởng lũy kế (%) cho toàn bộ giai đoạn 2025–2030. - So sánh doanh thu và chi phí hoạt động từng CLB để đánh giá hiệu suất tài chính. - Phân tích mức độ hài lòng của học sinh và đối tác để đo lường giá trị phi tài chính.", "present": "Dashboard tổng hợp trên Smartsheet hoặc Power BI thể hiện: • Biểu đồ cột: Doanh thu từng CLB qua các năm. • Biểu đồ đường: Tăng trưởng lũy kế doanh thu. • Biểu đồ tròn: Cơ cấu nguồn thu theo loại hình chương trình. • Heatmap: Mức độ tham gia của học sinh và đối tác.", "verify": "Chưa điền", "report": "Báo cáo định kì gửi Ban Giám hiệu và Hội đồng Chiến lược mỗi 6 tháng. - Tích hợp kết quả KPI vào Báo cáo tổng kết năm học và Dashboard kết quả hoạt động CLB KH–CN. - Sử dụng biểu mẫu chuẩn hóa để đảm bảo tính nhất quán và đối chiếu số liệu tài chính.", "pts": [{"n": "1.1", "name": "Số lượng chương trình/CLB đang hoạt động trong năm học", "desc": "Tổng số CLB và chương trình KH–CN (STEM, Robotics, AI, Lập trình, Khoa học) được tổ chức và duy trì trong năm học."}, {"n": "1.2", "name": "Số chương trình mới mở trong năm", "desc": "Số CLB hoặc chương trình KH–CN được thành lập và triển khai lần đầu trong năm học."}, {"n": "2.1", "name": "Số sự kiện liên quan đến CLB STEM", "desc": "Tổng số hoạt động, sự kiện, workshop hoặc cuộc thi được tổ chức trong khuôn khổ CLB STEM"}, {"n": "2.2", "name": "Doanh thu từ CLB STEM", "desc": "Tổng doanh thu thu được từ phí tham gia, tài trợ, hoặc hợp tác của các hoạt động thuộc CLB STEM."}, {"n": "2.3", "name": "Chi phí vận hành chương trình CLB STEM (USD/VND)", "desc": "Tổng chi phí trực tiếp phục vụ tổ chức, vận hành, truyền thông, và trang thiết bị của CLB STEM."}, {"n": "2.4", "name": "Số lượng học sinh tham gia CLB STEM", "desc": "Tổng số học sinh tham gia các hoạt động, sự kiện, hoặc dự án của CLB STEM trong năm học."}, {"n": "2.5", "name": "Số lượng đối tác & doanh nghiệp đồng hành (sponsoring partners) CLB STEM", "desc": "Số lượng tổ chức, doanh nghiệp hoặc cá nhân tài trợ, hỗ trợ hoặc hợp tác cùng CLB STEM."}, {"n": "3.1", "name": "Số sự kiện liên quan đến CLB Robotics & AI", "desc": "Số hoạt động, cuộc thi, workshop hoặc dự án công nghệ thuộc CLB Robotics & AI được tổ chức trong năm học."}, {"n": "3.2", "name": "Doanh thu từ CLB Robotics & AI", "desc": "Tổng doanh thu thu được từ học phí, tài trợ, hoặc hợp tác của CLB Robotics & AI."}, {"n": "3.3", "name": "Chi phí vận hành chương trình CLB Robotics & AI (USD/VND)", "desc": "Chi phí dành cho tổ chức lớp học, mua thiết bị, phần mềm, vật tư và truyền thông của CLB Robotics & AI."}, {"n": "3.4", "name": "Số lượng học sinh tham gia CLB Robotics & AI", "desc": "Tổng số học sinh LHBS tham gia các lớp học, cuộc thi hoặc hoạt động của CLB Robotics & AI trong năm học."}, {"n": "3.5", "name": "Số lượng đối tác & doanh nghiệp đồng hành (sponsoring partners) CLB Robotics & AI", "desc": "Số doanh nghiệp hoặc tổ chức công nghệ hỗ trợ hoặc đồng hành trong hoạt động CLB Robotics & AI."}, {"n": "4.1", "name": "Số sự kiện liên quan đến CLB Lập trình (Programming)", "desc": "Tổng số workshop, khóa học, hackathon, hoặc cuộc thi coding thuộc CLB Lập trình."}, {"n": "4.2", "name": "Doanh thu từ CLB Lập trình (Programming)", "desc": "Doanh thu từ phí đăng kí, học phí, tài trợ hoặc hợp tác với đối tác công nghệ."}, {"n": "4.3", "name": "Chi phí vận hành chương trình CLB Lập trình (Programming) (USD/VND)", "desc": "Chi phí tổ chức lớp học, phần mềm, bản quiền, trang thiết bị và nhân sự phụ trách CLB."}, {"n": "4.4", "name": "Số lượng học sinh tham gia CLB Lập trình (Programming)", "desc": "Tổng số học sinh tham gia ít nhất một hoạt động hoặc khóa học lập trình trong năm học."}, {"n": "4.5", "name": "Số lượng đối tác & doanh nghiệp đồng hành (sponsoring partners) CLB Lập trình (Programming)", "desc": "Số lượng đối tác công nghệ, doanh nghiệp hoặc đơn vị đào tạo cùng tài trợ, giảng dạy hoặc hỗ trợ CLB."}, {"n": "5.1", "name": "Số sự kiện liên quan đến CLB Khoa học (Science Club)", "desc": "Số buổi thí nghiệm, triển lãm, dự án nghiên cứu, hoặc hội thi khoa học được tổ chức trong CLB."}, {"n": "5.2", "name": "Doanh thu từ CLB Khoa học (Science Club)", "desc": "Tổng doanh thu thu được từ các hoạt động của CLB Khoa học, bao gồm tài trợ và phí tham dự."}, {"n": "5.3", "name": "Chi phí vận hành chương trình CLB Khoa học (Science Club) (USD/VND)", "desc": "Chi phí nguyên vật liệu, thí nghiệm, nhân sự hướng dẫn và truyền thông của CLB Khoa học."}, {"n": "5.4", "name": "Số lượng học sinh tham gia CLB Khoa học (Science Club) (Programming)", "desc": "Số lượng học sinh tham gia các hoạt động, dự án hoặc triển lãm thuộc CLB Khoa học."}, {"n": "5.5", "name": "Số lượng đối tác & doanh nghiệp đồng hành (sponsoring partners) CLB Khoa học (Science Club)", "desc": "Số lượng đối tác, viện nghiên cứu, hoặc doanh nghiệp tham gia hỗ trợ CLB Khoa học."}, {"n": "6.1", "name": "Số sự kiện cuộc thi & triển lãm KH-CN", "desc": "Tổng số cuộc thi, ngày hội hoặc triển lãm KH–CN được LHBS tổ chức trong năm học."}, {"n": "6.2", "name": "Doanh thu từ các cuộc thi & triển lãm KH–CN", "desc": "Tổng doanh thu từ phí tham dự, tài trợ, và hợp tác tổ chức các sự kiện KH–CN."}, {"n": "6.3", "name": "Chi phí vận hành các cuộc thi & triển lãm KH–CN (USD/VND)", "desc": "Tổng chi phí tổ chức, thuê địa điểm, vật tư, nhân sự và truyền thông cho các sự kiện KH–CN."}, {"n": "6.4", "name": "Số lượng học sinh tham gia các cuộc thi & triển lãm KH–CN (Programming)", "desc": "Tổng số học sinh LHBS tham gia trực tiếp vào các cuộc thi hoặc triển lãm KH–CN."}, {"n": "6.5", "name": "Số lượng đối tác & doanh nghiệp đồng hành (sponsoring partners) các cuộc thi & triển lãm KH–CN", "desc": "Số doanh nghiệp, trường đại học hoặc tổ chức hợp tác, tài trợ hoặc tham gia trưng bày."}, {"n": "7", "name": "Tổng doanh thu từ tất cả chương trình trong năm (USD/VND)", "desc": "[2.2]+[3.2]+[4.2]+[5.2]+[6.2] Tổng hợp toàn bộ doanh thu từ các CLB và sự kiện KH–CN trong năm học."}, {"n": "8", "name": "Tỉ lệ tăng trưởng doanh thu so với năm trước (%)", "desc": "(([7] năm nay - [7] năm trước)/[7] năm trước))*100 Tăng trưởng phần trăm doanh thu toàn bộ chương trình KH–CN so với năm học trước."}, {"n": "9", "name": "Tỉ lệ tăng trưởng các sự kiện Câu lạc bộ STEM, Robotics AI, Lập trình và Khoa học", "desc": "(([1.1] năm nay - [1.1] năm trước)/[1.1] năm trước))*100 Phần trăm tăng trưởng về số lượng hoạt động, sự kiện KH–CN so với năm học trước."}, {"n": "10", "name": "Tổng số lượt học sinh tham gia các Câu lạc bộ STEM, Robotics AI, Lập trình và Khoa học", "desc": "[2.4]+[3.4]+[4.4]+[5.4]+[6.4] Tổng hợp số lượt học sinh LHBS tham gia ít nhất một hoạt động, lớp học, cuộc thi hoặc sự kiện thuộc các CLB KH–CN trong năm học."}, {"n": "11", "name": "Tỉ lệ tăng trưởng số học sinh tham gia các Câu lạc bộ STEM, Robotics AI, Lập trình và Khoa học", "desc": "(([10] năm nay - [10] năm trước)/[10] năm trước))*100 Tăng trưởng phần trăm về số học sinh tham gia tổng thể các CLB KH–CN qua các năm."}, {"n": "12", "name": "Mức độ hài lòng của học sinh và đối tác tham gia các Câu lạc bộ STEM, Robotics AI, Lập trình và Khoa học", "desc": "Điểm hoặc tỷ lệ phần trăm đánh giá “hài lòng” trở lên của học sinh và đối tác tham gia các CLB KH–CN."}], "cut": ["31/12", "31/3", "30/6", "30/9"], "cutNote": "tổng hợp sơ bộ hằng quý", "review": [], "out": "3.2"}, {"c": "3.2.2", "n": "50% học sinh có nguyện vọng du học trúng tuyển vào đại học quốc tế qua quan hệ đối tác LHBS đến năm 2030", "def": "Chỉ số này theo dõi tỷ lệ học sinh tốt nghiệp LHBS có nguyện vọng du học và thực sự theo học tại các trường quốc tế thông qua: - Các quan hệ hợp tác học thuật quốc tế của LHBS. - Chương trình tư vấn hướng nghiệp và định hướng tuyển sinh đại học của LHBS. - Các lộ trình trao đổi – chuyển tiếp hoặc thỏa thuận liên thông (articulation agreements).", "why": "Mở ra cơ hội toàn cầu – Chứng minh rằng LHBS trang bị cho học sinh năng lực để thành công trong môi trường quốc tế cạnh tranh. - Củng cố danh tiếng – Tỷ lệ du học cao giúp LHBS trở thành lựa chọn hàng đầu cho các gia đình định hướng quốc tế. - Xây dựng mạng lưới cựu học sinh toàn cầu – Học sinh tốt nghiệp du học trở thành đại sứ lan tỏa hình ảnh LHBS ra thế giới. - Truyền cảm hứng vươn xa – Khuyến khích học sinh đặt mục tiêu cao hơn khi biết rằng LHBS có lộ trình hỗ trợ rõ ràng và chuyên nghiệp để vào các trường đại học hàng đầu thế giới. Đạt được KPI này có nghĩa là LHBS trở thành: “Bệ phóng nơi những ước mơ địa phương cất cánh vươn tới cơ hội toàn cầu.”", "asp": "Đến năm 2030, ít nhất 50% học sinh có nguyện vọng du học và sử dụng dịch vụ tư vấn hướng nghiệp của LHBS trúng tuyển vào các trường đại học quốc tế thông qua các mối quan hệ đối tác của LHBS - khẳng định LHBS là cầu nối tin cậy giúp học sinh Việt Nam tiếp cận nền giáo dục đại học toàn cầu.", "unit": "% (phần trăm học sinh có nguyện vọng du học và sử dụng dịch vụ tư vấn LHBS nhập học thành công tại các trường đối tác quốc tế)", "method": "[Tỉ lệ HS nhập học thành công thông qua dịch vụ tư vấn LHBS] = ([(Tổng số HS nhập học thành công qua kênh tư vấn của LHBS] / [Tổng số HS có nguyện vọng du học và dùng dịch vụ tư vấn LHBS])*100.", "split": "1. Khu vực du học: châu Á, Úc, châu Âu, Bắc Mỹ. 2. Loại trường đối tác: đối tác chiến lược, đối tác chương trình chuyển tiếp (articulation), đối tác học bổng. 3. Ngành học đăng kí: STEM, Kinh tế, Nghệ thuật, Xã hội, Y – Sinh. 4. Giới tính học sinh (nam/nữ). 5. Theo năm học & khóa tốt nghiệp.", "collect": "1. Thu thập danh sách học sinh có nguyện vọng du học từ bộ phận Tư vấn Hướng nghiệp & Tuyển sinh quốc tế. 2. Ghi nhận số học sinh tham gia các buổi tư vấn, workshop, mentoring (qua biểu mẫu đăng kí). 3. Xác minh kết quả trúng tuyển và nhập học thông qua: • Thư mời nhập học (Offer/Acceptance Letter). • Xác nhận nhập học chính thức từ trường đối tác. 4. Cập nhật cơ sở dữ liệu định kì (theo quý và cuối năm học). 5. Thực hiện khảo sát hài lòng của học sinh & phụ huynh sau quá trình tư vấn và nhập học.", "src": "Hồ sơ tư vấn du học (Career & Study Abroad Counseling Database). - Báo cáo hoạt động của Phòng Quan hệ đối ngoại và Trung tâm Tư vấn Hướng nghiệp – Du học. - Thư mời nhập học và xác nhận enrollment từ các trường đối tác. - Khảo sát mức độ hài lòng của học sinh và phụ huynh.", "freq": "Hàng quý: cập nhật tình hình đăng kí và trúng tuyển. - Cuối năm học (tháng 5–6): tổng hợp kết quả trúng tuyển và nhập học. - Tháng 8–9: xác nhận enrollment chính thức (theo lịch nhập học quốc tế).", "owner": "Chưa điền", "store": "Cơ sở dữ liệu tư vấn du học trên hệ thống Smartsheet/Google Drive (Career & University Placement Tracker). - Hồ sơ xác nhận nhập học lưu tại Trung tâm Tư vấn Hướng nghiệp & Du học.", "analyze": "Phân tích tỷ lệ HS có nguyện vọng du học, HS được tư vấn, HS trúng tuyển, và HS nhập học thành công qua đối tác LHBS. - Tính toán tỷ lệ HS đạt học bổng quốc tế, và tỷ lệ HS nhập học chính thức (enrollment rate). - Phân tích xu hướng theo năm học, ngành học, và khu vực du học để xác định thị trường tiềm năng và đối tác hiệu quả. - Tổng hợp kết quả hài lòng của HS và phụ huynh nhằm cải thiện chất lượng tư vấn.", "present": "Dashboard theo dõi theo quý trên Smartsheet hoặc Power BI hiển thị: • Biểu đồ cột: số HS trúng tuyển & nhập học qua từng năm. • Biểu đồ tròn: phân bố theo khu vực và loại trường đối tác. • Biểu đồ đường: xu hướng tăng trưởng tỷ lệ thành công qua các năm. • Chỉ báo hài lòng (Satisfaction Index) dưới dạng % hoặc thang điểm trung bình.", "verify": "Chưa điền", "report": "Báo cáo định kì 6 tháng/lần gửi Ban Giám hiệu và Hội đồng Chiến lược LHBS. - Báo cáo tổng hợp cuối năm học (tháng 6–7) kèm phân tích so sánh theo năm. - Tích hợp kết quả KPI vào Báo cáo Tác động Hướng nghiệp – Du học trong hệ thống KPI chiến lược LHBS.", "pts": [{"n": "1.1", "name": "Số học sinh có nguyện vọng du học", "desc": "Số lượng học sinh bày tỏ nguyện vọng hoặc đăng kí chương trình tư vấn hướng nghiệp – du học với LHBS trong năm học."}, {"n": "1.2", "name": "Số trường đại học quốc tế đối tác LHBS có tuyển sinh trong năm học", "desc": "Số trường ĐH quốc tế có hoạt động kí kết, nhận học sinh hoặc phối hợp chương trình tư vấn – xét tuyển cùng LHBS trong năm học."}, {"n": "1.3", "name": "Số chương trình liên kết / học bổng / đường dẫn du học (articulation / exchange-to-degree)", "desc": "Số chương trình chuyển tiếp, học bổng hoặc pathway do LHBS và đối tác quốc tế đồng tổ chức trong năm học."}, {"n": "2.1", "name": "Số học sinh sử dụng dịch vụ tư vấn hướng nghiệp & du học LHBS", "desc": "Số học sinh được hỗ trợ trực tiếp qua các buổi tư vấn, workshop, mentoring, hoặc hồ sơ du học do LHBS cung cấp."}, {"n": "2.2", "name": "Tỉ lệ HS có nguyện vọng du học sử dụng dịch vụ tư vấn (%)", "desc": "(Số HS sử dụng dịch vụ tư vấn / Số HS có nguyện vọng du học) × 100."}, {"n": "2.3", "name": "Số buổi tư vấn hướng nghiệp & định hướng du học tổ chức trong năm học", "desc": "Tổng số buổi workshop, hội thảo, mentoring hoặc phiên tư vấn cá nhân được LHBS tổ chức cho học sinh có định hướng du học."}, {"n": "3.1", "name": "Số học sinh trúng tuyển vào các trường ĐH quốc tế thông qua đối tác LHBS và qua kênh tư vấn của LHBS", "desc": "Số lượng học sinh nhận được thư mời nhập học (Offer/Acceptance Letter) từ các trường đại học quốc tế nằm trong danh sách đối tác chính thức của LHBS."}, {"n": "3.2", "name": "Số học sinh trúng tuyển vào các trường ĐH quốc tế ngoài hệ thống đối tác LHBS thông qua kênh tư vấn của LHBS", "desc": "Số lượng học sinh trúng tuyển vào các trường ĐH quốc tế khác (ngoài đối tác chính thức)."}, {"n": "3.3", "name": "Số học sinh nhận học bổng quốc tế qua LHBS", "desc": "Số HS trúng tuyển quốc tế có học bổng hoặc hỗ trợ tài chính thông qua LHBS"}, {"n": "3.4", "name": "Số HS nhập học thành công (enrollment rate)", "desc": "Số học sinh chính thức nhập học tại các trường quốc tế"}, {"n": "4", "name": "Tổng số học sinh trúng tuyển ĐH quốc tế thông qua kênh tư vấn của LHBS", "desc": "[3.1]+[3.2] Tổng số học sinh được nhận vào bất kì trường đại học quốc tế nào (bao gồm trong và ngoài hệ thống đối tác) thông qua kênh tư vấn của LHBS"}, {"n": "5", "name": "Tỉ lệ HS nhập học thành công trên tổng số HS có nguyện vọng du học và sử dụng dịch vụ tư vấn LHBS", "desc": "([4]/[2.1])*100 (Tổng số HS nhập học thành công qua kênh tư vấn của LHBS / Tổng số HS có nguyện vọng du học và dùng dịch vụ tư vấn LHBS)*100."}], "cut": ["31/12", "31/3", "30/6", "30/9"], "cutNote": "xác nhận nhập học tháng 8–9", "review": [], "out": "3.2"}],
      rfTree: [{"c": "1", "t": "Cung cấp chương trình và lộ trình học tập cá nhân hóa, giúp học sinh phát triển toàn diện và sẵn sàng bước vào đại học chất lượng cao trong nước và quốc tế.", "out": [{"c": "1.1", "t": "Chương trình và môi trường đào tạo của LHBS được quốc tế hóa, gắn với bản sắc Việt Nam", "act": [{"c": "1.1.1", "t": "Liên kết đào tạo chương trình quốc tế"}, {"c": "1.1.2", "t": "Tổ chức các hoạt động trải nghiệm với HS quốc tế"}, {"c": "1.1.3", "t": "Kiểm định cơ sở giáo dục theo chuẩn chất lượng quốc tế"}]}, {"c": "1.2", "t": "Học sinh đáp ứng chuẩn đầu ra và phát triển năng lực thế kỉ 21 thông qua lộ trình học tập cá nhân hóa", "act": [{"c": "1.2.1", "t": "Xây dựng bộ công cụ đánh giá chuẩn đầu ra cho học sinh ở từng cấp học"}, {"c": "1.2.2", "t": "Số hóa hệ thống lưu trữ hồ sơ minh chứng đánh giá CĐR cho toàn bộ hồ sơ học sinh"}, {"c": "1.2.3", "t": "Đào tạo phương pháp giảng dạy, đánh giá học sinh mới theo CĐR"}]}]}, {"c": "2", "t": "Kiến tạo và duy trì môi trường giảng dạy và học tập gắn kiến thức với thực tiễn và có tác động tích cực tới cộng đồng", "out": [{"c": "2.1", "t": "Các dự án học tập và nghiên cứu sáng tạo, thiết thực và có giá trị gắn kết với cộng đồng", "act": [{"c": "2.1.1", "t": "Tổ chức các hoạt động trải nghiệm gắn bài học với thực tế cuộc sống thông qua hợp tác với các tổ chức, hiệp hội, DN"}, {"c": "2.1.2", "t": "Xây dựng khu thực hành trải nghiệm cho dự án của HS"}]}, {"c": "2.2", "t": "LBHS được định vị là hình mẫu hàng đầu trong mô hình hợp tác hiệu quả giữa trường học và cộng đồng", "act": [{"c": "2.2.1", "t": "Liên kết thực hiện dự án với các tổ chức phi lợi nhuận và đối tác học thuật có uy tín"}, {"c": "2.2.2", "t": "Thiết lập liên minh đào tạo STEM trong giáo dục phổ thông ở Đồng Nai do LHBS chủ trì"}]}]}, {"c": "3", "t": "Phát triển mô hình vận hành linh hoạt và hiệu quả, đảm bảo tính bền vững tài chính đi đôi với cam kết nâng cao chất lượng giáo dục.", "out": [{"c": "3.1", "t": "Áp dụng hệ thống quản lí chất lượng theo bộ tiêu chuẩn kiểm định quốc tế tạo sự phát triển bền vững và cải tiến liên tục", "act": [{"c": "3.1.1", "t": "Thực hiện kiểm định giáo dục quốc tế ISO 21001:2018"}, {"c": "3.1.2", "t": "Số hóa các qui trình đảm bảo chất lượng ISO"}, {"c": "3.1.3", "t": "Thiết lập hệ thống thu thập, phân tích và báo cáo dữ liệu chất lượng nhằm theo dõi và cải tiến liên tục."}]}, {"c": "3.2", "t": "Thiết lập mô hình kinh doanh có nguồn thu đa dạng, hiệu quả, linh hoạt và bền vững", "act": [{"c": "3.2.1", "t": "Đưa ra thị trường các chương trình giáo dục và dịch vụ mới có mức giá phù hợp với phân khúc khách hàng thu nhập tầm trung hoặc cao cấp."}, {"c": "3.2.2", "t": "Xây dựng và thực hiện chế độ đãi ngộ dựa trên năng lực và thành tích đóng góp vào mô hình kinh doanh của trường"}]}]}],
      rfBaseline: {"KPI 1": [{"u": "MN Long Khánh, MN Biên Hòa, Tiểu học, THCS, THPT", "p": 38, "nb": false}], "KPI 2": [{"u": "THPT", "p": 38, "nb": false}], "KPI 3": [{"u": "MN Long Khánh", "p": 38, "nb": false}, {"u": "MN Biên Hòa", "p": 38, "nb": false}, {"u": "Tiểu học, THCS, THPT", "p": 38, "nb": false}], "KPI 4": [{"u": "Toàn hệ thống", "p": 38, "nb": false}], "KPI 5": [{"u": "Toàn hệ thống", "p": 38, "nb": false}], "KPI 6": [{"u": "Toàn hệ thống", "p": 38, "nb": false}], "KPI 7": [{"u": "Toàn hệ thống", "p": 25, "nb": false}], "1.1.1": [{"u": "Toàn hệ thống", "p": 25, "nb": true}], "1.1.2": [{"u": "MN Long Khánh", "p": 25, "nb": false}, {"u": "MN Biên Hòa", "p": 25, "nb": false}, {"u": "Tiểu học, THCS, THPT", "p": 25, "nb": false}], "1.2.1": [{"u": "MN Long Khánh", "p": 25, "nb": true}, {"u": "MN Biên Hòa", "p": 25, "nb": true}, {"u": "Tiểu học", "p": 25, "nb": true}, {"u": "THCS, THPT", "p": 25, "nb": true}], "1.2.2": [{"u": "MN Long Khánh", "p": 25, "nb": true}, {"u": "MN Biên Hòa", "p": 25, "nb": true}, {"u": "Tiểu học", "p": 25, "nb": true}, {"u": "Tiểu học, THCS", "p": 25, "nb": true}], "2.1.1": [{"u": "MN Long Khánh", "p": 25, "nb": false}, {"u": "MN Biên Hòa", "p": 25, "nb": false}, {"u": "Tiểu học, THCS, THPT", "p": 38, "nb": false}], "2.1.2": [{"u": "MN Long Khánh", "p": 0, "nb": false}, {"u": "MN Biên Hòa", "p": 0, "nb": false}, {"u": "Tiểu học", "p": 0, "nb": false}, {"u": "THCS, THPT", "p": 0, "nb": false}], "2.2.1": [{"u": "MN Long Khánh", "p": 0, "nb": false}, {"u": "MN Biên Hòa", "p": 0, "nb": false}, {"u": "Tiểu học, THCS, THPT", "p": 0, "nb": false}], "2.2.2": [{"u": "MN Long Khánh", "p": 0, "nb": false}, {"u": "MN Biên Hòa", "p": 0, "nb": false}, {"u": "Tiểu học", "p": 0, "nb": false}, {"u": "THCS, THPT", "p": 0, "nb": false}], "3.1.1": [{"u": "Toàn hệ thống", "p": 0, "nb": true}], "3.2.1": [{"u": "MN Long Khánh", "p": 0, "nb": false}, {"u": "MN Biên Hòa", "p": 0, "nb": false}, {"u": "Tiểu học", "p": 0, "nb": false}, {"u": "THCS, THPT", "p": 0, "nb": false}, {"u": "Toàn hệ thống", "p": 0, "nb": false}], "3.2.2": [{"u": "Toàn hệ thống", "p": 0, "nb": false}]},

      dictGroups: [
        { k: 'ALL', t: 'Tất cả' },
        { k: 'TS', t: 'Quy mô – tuyển sinh', en: 'Enrollment' },
        { k: 'YT', t: 'An toàn – y tế', en: 'Safety & health' },
        { k: 'BA', t: 'Bếp ăn – bán trú', en: 'Food & boarding services' },
        { k: 'TC', t: 'Tài chính cơ bản', en: 'Basic financials' }
      ],
      modeText: { tay: 'Nhập tay', ban: 'Xuất file', tu: 'Tự động' },
      dictStatusText: { nhap: 'Nháp IT', kt: 'M&E đã kiểm tra', duyet: 'Đã duyệt' },
      dictFields: [
        { k: 'num', t: 'Tử số' },
        { k: 'den', t: 'Mẫu số' },
        { k: 'rule', t: 'Quy tắc, loại trừ' },
        { k: 'split', t: 'Phân tổ' },
        { k: 'tgt', t: 'Mục tiêu' },
        { k: 'rf', t: 'Tham chiếu Results Framework' },
        { k: 'f', t: 'Tần suất' },
        { k: 'cut', t: 'Ngày chốt' },
        { k: 'src', t: 'Hệ thống nguồn' }
      ],
      kpiDict: [
        { c: 'TS-01', rfk: 'KPI 1', g: 'TS', n: 'Sĩ số học sinh hiện diện', u: 'Học sinh', f: 'Tháng', cut: 'Ngày làm việc cuối tháng, 17:00', num: 'Số HS đang đi học tại ngày chốt, gồm HS vắng có xin phép trên ME', den: '—', rule: 'Không tính HS đã nộp đơn rút nhưng chưa xử lý xong; mỗi HS tính một lần', split: 'Lớp, khối, cấp học, cơ sở', tgt: 'Kế hoạch năm học', rf: 'KPI 1', src: 'ME – Quản lý học sinh (Basic data)', now: 'tay', goal: 'tu', own: 'Hiệu trưởng từng cơ sở', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'good', used: 'Hội đồng trường, Quy mô & giữ chân', note: 'Hiện lấy từ Excel vận hành; ME đã có dữ liệu nên có thể tự động sớm nhất.' },
        { c: 'TS-02', rfk: 'KPI 1', g: 'TS', n: 'Tỷ lệ lấp đầy công suất', u: '%', f: 'Tháng', cut: 'Ngày làm việc cuối tháng, 17:00', num: 'Sĩ số HS hiện diện (TS-01)', den: 'Tổng công suất thiết kế = chỗ tối đa mỗi lớp × số lớp', rule: 'Mẫu số là công suất thiết kế, không phải chỉ tiêu tuyển sinh', split: 'Lớp, khối, cấp học, cơ sở', tgt: '100% công suất', rf: 'KPI 1: tuyển sinh đạt 100% công suất', src: 'ME + danh mục phòng học (CSVC)', now: 'tay', goal: 'tu', own: 'Hiệu trưởng + CSVC', chk: 'M&E', apr: 'Hội đồng trường', st: 'nhap', rd: 'none', used: 'Chưa hiển thị', note: 'Chưa có công suất thiết kế chuẩn theo lớp. Dashboard đang dùng % kế hoạch thay cho KPI 1, cần tách hai chỉ số này.' },
        { c: 'TS-03', rfk: 'KPI 1', g: 'TS', n: 'Tỷ lệ hoàn thành mục tiêu tuyển sinh năm học', u: '%', f: 'Tháng', cut: 'Ngày làm việc cuối tháng, 17:00', num: 'Sĩ số HS hiện diện (TS-01)', den: 'Chỉ tiêu tuyển sinh năm học đã phê duyệt', rule: 'Chỉ tiêu chốt đầu năm học, không điều chỉnh giữa năm', split: 'Lớp, khối, cấp học, cơ sở', tgt: 'Kế hoạch năm học', rf: 'KPI 1', src: 'ME + kế hoạch năm học', now: 'tay', goal: 'tu', own: 'Hiệu trưởng từng cơ sở', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'good', used: 'Hội đồng trường, Quy mô & giữ chân, Mô phỏng', note: '' },
        { c: 'TS-04', rfk: 'KPI 3', g: 'TS', n: 'Tỷ lệ học sinh rút học / chuyển đi', u: '%', f: 'Tháng, học kỳ', cut: 'Ngày làm việc cuối tháng', num: 'Số HS rút ròng trong kỳ', den: 'Tổng số HS đầu năm học', rule: 'Tách 3 loại: Tốt nghiệp (không tính), Chuyển trường, Rút hồ sơ. Lý do theo danh mục chuẩn, bỏ mục "Khác". Ghi trường chuyển đến', split: 'Lớp, khối, cấp học, cơ sở, lý do, nơi đến', tgt: 'Dưới 10%/năm, theo dõi theo nhịp tháng', rf: 'KPI 3: rút học dưới 10%', src: 'ME – phiếu rút hồ sơ', now: 'tay', goal: 'tu', own: 'Hiệu trưởng từng cơ sở', chk: 'M&E', apr: 'Hội đồng trường', st: 'nhap', rd: 'part', used: 'Quy mô & giữ chân, Bản đồ tuyển sinh', note: 'Hiện gộp chung một loại "rút"; 14/53 ca để lý do "Khác"; 0/53 ca ghi trường chuyển đến.' },
        { c: 'TS-05', rfk: 'KPI 5', g: 'TS', n: 'Số lượng lead', u: 'Lead', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số lead hợp lệ thu được trong tháng qua các kênh (Digital, Event, Hotline, Referral)', den: '—', rule: 'Tách "data thô" và "lead hợp lệ" (liên lạc được, đúng độ tuổi). Khử trùng theo số điện thoại', split: 'Khối, cấp học, kênh nguồn, chiến dịch, tư vấn viên', tgt: 'Kế hoạch năm học (Liên cấp 1.500, MNTB 800, MNLK 600)', rf: 'Đầu vào của KPI chuyển đổi', src: 'CRM tuyển sinh (đang phát triển); hiện Excel tracking TVTS', now: 'tay', goal: 'tu', own: 'Marketing – Trưởng nhóm TVTS', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'part', used: 'Tuyển sinh, Bản đồ tuyển sinh', note: 'Định nghĩa "lead hợp lệ" là đề xuất của IT để tránh mẫu số bị thổi phồng bởi lead rác từ quảng cáo.' },
        { c: 'TS-06', rfk: 'KPI 5', g: 'TS', n: 'Tỷ lệ chuyển đổi funnel', u: '%', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số HS đăng ký nhập học mới', den: 'Tổng số lead (TS-05)', rule: 'Tính theo cohort: lead vào tháng T, theo dõi đến hết tháng T+3. Báo cáo kèm tỷ lệ theo tháng để so với số cũ', split: 'Kênh nguồn, tư vấn viên, khối, cấp', tgt: '30%', rf: 'MASTER KPI: KPI 5 (phương án 19/10 ghi KPI 6) · chờ xác nhận mã', src: 'CRM tuyển sinh + ME', now: 'tay', goal: 'tu', own: 'Marketing – Trưởng nhóm TVTS', chk: 'M&E', apr: 'Hội đồng trường', st: 'nhap', rd: 'part', used: 'Hội đồng trường, Tuyển sinh, Bản đồ tuyển sinh', note: 'Theo MASTER KPI, KPI 5 đo inquiry → nhập học, chốt 3 lần/năm (31/8, 31/12, 31/5). Rà soát của chuyên gia đề nghị tách KPI 5 thành 2 mã: chuyển đổi và hài lòng.' },
        { c: 'TS-07', rfk: 'KPI 5', g: 'TS', n: 'Chi phí tuyển sinh trên mỗi học sinh (CAC)', u: 'VNĐ/HS', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Tổng chi phí marketing và tuyển sinh lũy kế', den: 'Số HS nhập học mới lũy kế', rule: 'Chi phí gồm quảng cáo, hội thảo, đại sứ, ưu đãi cho HS', split: 'Hạng mục chi phí, kênh, khối, cấp', tgt: 'Kế hoạch năm học', rf: 'Hỗ trợ KPI chuyển đổi', src: 'Kế toán + ME', now: 'tay', goal: 'ban', own: 'Kế toán + Marketing', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Mô phỏng (giả định)', note: 'Chưa có chi phí theo kênh.' },

        { c: 'YT-01', g: 'YT', n: 'Sự cố tai nạn thương tích, dị ứng, ngộ độc', u: 'Vụ', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số vụ sự cố y tế nghiêm trọng hoặc sai sót xử lý sơ cấp cứu', den: '—', rule: '"Nghiêm trọng" = phải chuyển viện hoặc nghỉ học từ 1 ngày trở lên. Báo cáo trong 24 giờ, kèm biên bản', split: 'Cơ sở, khu vực, loại sự cố', tgt: '0 vụ', rf: 'Ưu tiên an toàn (19/10)', src: 'Sổ y tế học đường', now: 'tay', goal: 'ban', own: 'Y tế + Hiệu trưởng', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: 'Định nghĩa mức "nghiêm trọng" là đề xuất của IT, cần Y tế xác nhận.' },
        { c: 'YT-02', g: 'YT', n: 'Tỷ lệ hoàn thành khám sức khỏe định kỳ', u: '%', f: 'Học kỳ', cut: 'Cuối học kỳ', num: 'Số HS được khám và lập hồ sơ theo dõi', den: 'Tổng sĩ số (TS-01)', rule: 'Tính HS có hồ sơ khám trong năm học hiện tại', split: 'Lớp, khối, cơ sở', tgt: '100%', rf: 'Ưu tiên y tế (19/10)', src: 'Hồ sơ sức khỏe học sinh', now: 'tay', goal: 'ban', own: 'Y tế', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'YT-03', g: 'YT', n: 'Tỷ lệ HS có BMI ngoài ngưỡng độ tuổi', u: '%', f: 'Tháng (mầm non), khi có kết quả khám (phổ thông)', cut: 'Ngày cân đo', num: 'Số HS có BMI thấp hoặc cao hơn ngưỡng độ tuổi', den: 'Tổng số HS được cân đo', rule: 'Ngưỡng theo chuẩn WHO cho độ tuổi', split: 'Lớp, khối, giới tính', tgt: 'Dưới 10%', rf: 'Ưu tiên y tế (19/10)', src: 'Hồ sơ sức khỏe học sinh', now: 'tay', goal: 'ban', own: 'Y tế', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'YT-04', g: 'YT', n: 'Chi phí y tế bình quân mỗi học sinh', u: 'VNĐ/HS', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Chi phí y tế trong kỳ', den: 'Sĩ số bình quân trong kỳ', rule: 'So với định mức ngân sách đã phê duyệt', split: 'Cơ sở', tgt: '40.000 đồng/HS', rf: 'Ưu tiên y tế (19/10)', src: 'Kế toán + Y tế', now: 'tay', goal: 'ban', own: 'Y tế + Kế toán', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'YT-05', g: 'YT', n: 'Ca bệnh truyền nhiễm theo lớp', u: 'Ca', f: 'Tuần', cut: 'Thứ 6 hằng tuần', num: 'Số ca bệnh truyền nhiễm được ghi nhận (tay chân miệng, cúm, sốt xuất huyết…)', den: '—', rule: 'Cảnh báo ổ dịch khi một lớp có từ 2 ca trong 7 ngày', split: 'Lớp, cơ sở, loại bệnh', tgt: 'Không có ổ dịch kéo dài quá 14 ngày', rf: 'Ưu tiên y tế (19/10)', src: 'Sổ y tế học đường', now: 'tay', goal: 'ban', own: 'Y tế + Hiệu trưởng', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'part', add: true, used: 'Vận hành ưu tiên', note: 'IT đề xuất thêm: tháng 9 có tay chân miệng và cúm A nhưng chỉ ghi dạng chữ, không có số ca hay ngưỡng.' },

        { c: 'BA-01', g: 'BA', n: 'Số vụ ngộ độc thực phẩm', u: 'Vụ', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số vụ ngộ độc thực phẩm tại các cơ sở', den: '—', rule: 'Tính cả nghi ngộ độc đã báo cơ quan y tế', split: 'Cơ sở, bữa ăn', tgt: '0 vụ', rf: 'Ưu tiên bếp ăn (19/10)', src: 'Bếp + Y tế', now: 'tay', goal: 'ban', own: 'Bếp', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'BA-02', g: 'BA', n: 'Tỷ lệ hài lòng về bếp ăn', u: '%', f: 'Cuối học kỳ', cut: 'Ngày đóng khảo sát', num: 'Số phiếu đánh giá từ mức Đạt trở lên', den: 'Tổng số phiếu hợp lệ', rule: 'Báo cáo kèm cỡ mẫu và tỷ lệ phản hồi; tách phụ huynh, học sinh, nội bộ', split: 'Cơ sở, đối tượng khảo sát', tgt: 'Trên 95%', rf: 'Ưu tiên bếp ăn (19/10)', src: 'qa.lhbs.vn (khảo sát)', now: 'ban', goal: 'tu', own: 'Bếp', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'part', used: 'Vận hành ưu tiên', note: 'Báo cáo tổng kết lưu ý nhiều khảo sát không nêu cỡ mẫu.' },
        { c: 'BA-03', rfk: '3.1.1', g: 'BA', n: 'Chứng nhận ISO 22000:2018', u: 'Chứng nhận', f: 'Năm học', cut: 'Cuối năm học', num: 'Trạng thái chứng nhận', den: '—', rule: 'Theo dõi theo mốc: đánh giá khoảng cách, đánh giá nội bộ, đánh giá chứng nhận', split: 'Cơ sở', tgt: 'Đạt chứng nhận', rf: 'Mục tiêu 3.1.2: số hóa quy trình và đảm bảo ISO', src: 'Ban ISO', now: 'tay', goal: 'tay', own: 'Ban ISO + Bếp', chk: 'QLCL', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'BA-04', g: 'BA', n: 'Tỷ lệ nhân sự bếp được tập huấn VSATTP', u: '%', f: 'Năm học', cut: 'Cuối học kỳ', num: 'Số nhân sự đã tập huấn', den: 'Tổng nhân sự phục vụ, chăm sóc bữa ăn', rule: 'Tính người duy nhất, không tính lượt', split: 'Cơ sở, bộ phận', tgt: '100%', rf: 'Ưu tiên bếp ăn (19/10)', src: 'HRM (đào tạo)', now: 'tay', goal: 'tu', own: 'Bếp + Nhân sự', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'BA-05', g: 'BA', n: 'Tỷ lệ vi phạm an toàn dịch vụ đưa rước', u: '%', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số vi phạm: đón trễ, về trễ, quên đón, quên điểm danh lên/xuống, kết thúc chuyến', den: 'Tổng lượt chuyến = (lượt đi + lượt về) × số ngày phục vụ', rule: 'Mọi vi phạm đều tính, kể cả đã khắc phục ngay', split: 'Tuyến, giám sát', tgt: 'Dưới 5%', rf: 'Ưu tiên an toàn (19/10)', src: 'Phần mềm xe đưa rước', now: 'tay', goal: 'tu', own: 'Bán trú – Xe đưa rước', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },
        { c: 'BA-06', g: 'BA', n: 'Số HS dùng dịch vụ ăn sáng, xe đưa rước', u: 'HS, % so cùng kỳ', f: 'Tháng', cut: 'Ngày làm việc cuối tháng', num: 'Số HS đăng ký dịch vụ trong tháng', den: 'Số HS cùng kỳ năm trước', rule: 'Tách riêng ăn sáng và xe đưa rước', split: 'Cơ sở, tuyến xe', tgt: 'Tăng 10% so cùng kỳ', rf: 'Ưu tiên bán trú (19/10)', src: 'Phần mềm thu phí', now: 'tay', goal: 'tu', own: 'Bán trú', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'part', used: 'Vận hành ưu tiên', note: 'Tháng 9 báo cáo có sụt giảm nhưng chưa có số.' },
        { c: 'BA-07', g: 'BA', n: 'Hiệu quả dịch vụ đưa rước', u: '%', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Doanh thu xe − chi phí thuê xe − chi phí giám sát − chi phí phần mềm', den: 'Doanh thu xe đưa rước', rule: 'Chi phí phân bổ theo tuyến', split: 'Tuyến', tgt: 'Tối thiểu 10%', rf: 'Ưu tiên tài chính dịch vụ (19/10)', src: 'Kế toán + Bán trú', now: 'tay', goal: 'ban', own: 'Bán trú + Kế toán', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: '' },

        { c: 'TC-01', rfk: 'KPI 7', g: 'TC', n: 'Doanh thu thuần so với kế hoạch', u: 'VNĐ, %', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Doanh thu thuần ghi nhận trong kỳ (học phí + dịch vụ)', den: 'Doanh thu kế hoạch cùng kỳ', rule: 'Ghi nhận theo kỳ học, không theo ngày thu tiền', split: 'Cơ sở, cấp học, loại doanh thu', tgt: 'Kế hoạch năm tài chính', rf: 'Ưu tiên "Doanh thu & Bottom line" (19/10)', src: 'Phần mềm thu phí + kế toán', now: 'tay', goal: 'ban', own: 'Kế toán', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'none', add: true, used: 'Vận hành ưu tiên', note: 'Phương án nêu ưu tiên doanh thu nhưng chưa có công thức. Phần mềm thu phí còn thủ công.' },
        { c: 'TC-02', rfk: 'KPI 7', g: 'TC', n: 'Tỷ suất lợi nhuận gộp', u: '%', f: 'Tháng, học kỳ', cut: 'Theo kỳ khóa sổ kế toán', num: 'Lợi nhuận gộp từ hoạt động giáo dục và dịch vụ bổ trợ', den: 'Doanh thu thuần', rule: 'Cần P&L theo trường và theo hoạt động', split: 'Cơ sở, hoạt động, dịch vụ', tgt: '50%', rf: 'MASTER KPI: KPI 7 (phương án 19/10 ghi KPI 4) · chờ xác nhận mã', src: 'Kế toán', now: 'tay', goal: 'ban', own: 'Kế toán + chủ dịch vụ', chk: 'M&E', apr: 'Hội đồng trường', st: 'nhap', rd: 'none', used: 'Vận hành ưu tiên', note: 'Theo MASTER KPI: chốt 2 lần/năm (giữa và cuối năm tài chính), chỉ dùng nội bộ.' },
        { c: 'TC-03', rfk: 'KPI 7', g: 'TC', n: 'Lợi nhuận ròng theo cơ sở (bottom line)', u: 'VNĐ', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Lợi nhuận sau toàn bộ chi phí, phân bổ chi phí chung theo quy tắc thống nhất', den: '—', rule: 'Quy tắc phân bổ chi phí khối văn phòng cần Ban điều hành duyệt', split: 'Cơ sở, Holding', tgt: 'Kế hoạch năm tài chính', rf: 'Ưu tiên "Doanh thu & Bottom line" (19/10)', src: 'Kế toán', now: 'tay', goal: 'ban', own: 'Kế toán', chk: 'M&E', apr: 'Hội đồng trường', st: 'nhap', rd: 'none', add: true, used: 'Vận hành ưu tiên', note: 'Chưa có P&L theo trường.' },
        { c: 'TC-04', rfk: '3.2.1', g: 'TC', n: 'Doanh thu CLB bổ trợ', u: 'VNĐ', f: 'Tháng', cut: 'Theo kỳ khóa sổ kế toán', num: 'Doanh thu từ CLB STEM, Robotics AI, Lập trình, Khoa học', den: '—', rule: 'Cần mã doanh thu, chi phí riêng theo CLB', split: 'CLB, cơ sở; tháng và lũy kế', tgt: 'Tổng doanh thu các năm đến 1 triệu USD', rf: 'KPI 3.2.1', src: 'Kế toán + CLB', now: 'tay', goal: 'ban', own: 'BGH + Kế toán', chk: 'M&E', apr: 'Ban điều hành', st: 'nhap', rd: 'part', used: 'Vận hành ưu tiên', note: 'Đã có số HS CLB (596/645), chưa có doanh thu.' }
      ],
      narrative: { t: 'Gợi ý đọc số · chờ M&E xác nhận', note: 'Câu kết luận do hệ thống tự soạn từ số liệu. M&E (phân tích và đọc số) rà soát, xác nhận trước khi dùng chính thức.' },
      pages: [
        { n: 0, t: 'Hội đồng trường', s: 'Hội đồng', grp: 'ov' },
        { n: 1, t: 'Quy mô & giữ chân', s: 'Quy mô', grp: 'A' },
        { n: 2, t: 'Tuyển sinh', s: 'Tuyển sinh', grp: 'A' },
        { n: 6, t: 'Bản đồ tuyển sinh', s: 'Bản đồ TS', grp: 'A' },
        { n: 8, t: 'Vận hành ưu tiên', s: 'Vận hành', grp: 'A' },
        { n: 3, t: 'Results Framework', s: 'Results FW', grp: 'D' },
        { n: 9, t: 'Từ điển KPI', s: 'Từ điển', grp: 'D' },
        { n: 4, t: 'Dữ liệu & đối soát', s: 'Đối soát', grp: 'D' },
        { n: 10, t: 'Học thuật & tiến bộ', s: 'Học thuật', grp: 'B' },
        { n: 11, t: 'Năng lực giáo viên', s: 'Năng lực GV', grp: 'C' },
        { n: 7, t: 'Đối sánh khu vực', s: 'Đối sánh', grp: 'pt' },
        { n: 5, t: 'Mô phỏng kịch bản', s: 'Mô phỏng', grp: 'pt' }
      ],
      pageGroups: [
        { k: 'ov', t: 'Tổng quan', row: 1 },
        { k: 'A', t: 'A · Vận hành (tháng)', row: 1 },
        { k: 'D', t: 'D · KPI chiến lược', row: 1 },
        { k: 'B', t: 'B · Học thuật · giai đoạn sau', row: 2, later: true },
        { k: 'C', t: 'C · Năng lực GV · giai đoạn sau', row: 2, later: true },
        { k: 'pt', t: 'Phân tích · có giả định', row: 2 }
      ],
      tierPages: {
        10: { k: 'Tầng B · Học thuật & tiến bộ · giai đoạn sau', lead: 'Theo rà soát CSDL, tầng này theo dõi kết quả học tập và phát triển của học sinh, dự giờ, hồ sơ chuyên môn và phát triển nghề nghiệp, tách "kết quả học sinh" khỏi "thực hành của giáo viên". Chưa dựng vì dữ liệu nguồn (LMS, Edubot-ME, dự giờ) chưa có định nghĩa khóa và mã định danh dùng chung.',
          show: ['Kết quả học tập, rèn luyện theo lớp, khối, cấp học; tỷ lệ đạt mức "Thành thạo" (KPI 1.2.1)', 'Đầu ra: tốt nghiệp, trúng tuyển đại học, du học (KPI 2, KPI 3.2.2)', 'Dự giờ và hồ sơ chuyên môn theo rubric có phiên bản', 'Chuyên cần học sinh như dữ liệu bối cảnh, không quy trực tiếp cho giáo viên (YF-01)', 'Hài lòng phụ huynh về tiến bộ học sinh (KPI 1.2.2) theo chuẩn khảo sát chung (YF-02)'],
          pre: ['Mã định danh dùng chung Học sinh, Lớp, Môn, Kỳ (mục 5.1)', 'Ma trận nguồn dữ liệu chính thức và khóa kỳ (RF-08)', 'Thang năng lực "Thành thạo" thống nhất; KPI 1.2.1 chưa có baseline', 'Quy định dùng AI và phân quyền dữ liệu học sinh (RF-07)'] },
        11: { k: 'Tầng C · Năng lực & hiệu suất giáo viên · giai đoạn sau', lead: 'Ba lớp liên thông: đánh giá định kỳ (thang 1–4), đánh giá năng lực (1–5), thi đua và ghi nhận. Rà soát của chuyên gia KPI xếp 6 Red Flag cho khung năng lực hiện tại; theo lộ trình, chỉ dựng dashboard sau khi khóa quy tắc chấm và chạy pilot.',
          show: ['Kết quả 3 lớp đánh giá theo giáo viên, tổ, cấp học, không cộng cơ học', 'Điều kiện chặn (an toàn, đạo đức) hiển thị tách khỏi điểm năng lực', 'Điểm theo tiêu chí con để chỉ ra nội dung cần bồi dưỡng', 'Độ nhất quán người chấm, tỷ lệ N/A theo vai trò'],
          pre: ['RF-01: chống đếm lặp giữa đánh giá năng lực và thi đua', 'RF-02: khóa thang điểm, sửa mẫu số đánh giá tháng mầm non', 'RF-03: ma trận điều kiện chặn', 'RF-04: làm sạch ngưỡng chồng lấn', 'RF-05: ma trận vai trò × tiêu chí, quy tắc N/A', 'RF-06: mã tiêu chí ổn định và bảng đối chiếu'] }
      },
      unitOptions: [
        { k: 'ALL', t: 'Toàn hệ thống' },
        { k: 'MNBH', t: 'MN Biên Hòa' },
        { k: 'MNLK', t: 'MN Long Khánh' },
        { k: 'TH', t: 'Tiểu học' },
        { k: 'THCS', t: 'THCS' },
        { k: 'THPT', t: 'THPT' }
      ],
      units: [
        { k: 'MNBH', ten: 'MN Biên Hòa (Trấn Biên)', owner: 'Hiệu trưởng MN Trấn Biên', don: 'MNBH', clbKey: 'MNBH', hp: 37.2, kh: 406, t5: 398, t8: 353, t9: 357, lop: 20, di: 12, di9: 2, den: 22, den9: 10,
          fmt: { k: 'ppt', t: 'PPTX · 11 slide' },
          khoi: [
            { k: 'Nhà trẻ', kh: 104, t8: 89, t9: 90, lop: 4, di: 6, den: 12 },
            { k: 'Mầm', kh: 100, t8: 77, t9: 80, lop: 5, di: 2, den: 3 },
            { k: 'Chồi', kh: 72, t8: 67, t9: 67, lop: 5, di: 2, den: 3 },
            { k: 'Lá', kh: 130, t8: 120, t9: 120, lop: 6, di: 2, den: 4 }
          ] },
        { k: 'MNLK', ten: 'MN Long Khánh', owner: 'Hiệu trưởng MN Long Khánh', don: 'MNLK', clbKey: 'MNLK', hp: 37.2, kh: 166, t5: 132, t8: 123, t9: 129, lop: 9, di: 10, di9: 4, den: 22, den9: 8,
          fmt: { k: 'pdf', t: 'PDF · 37 trang' },
          khoi: [
            { k: 'Nhà trẻ', kh: 76, t8: 48, t9: 51, lop: 2, di: 4, den: 13 },
            { k: 'Mầm', kh: 40, t8: 33, t9: 34, lop: 2, di: 5, den: 1 },
            { k: 'Chồi', kh: 24, t8: 22, t9: 23, lop: 3, di: 1, den: 5 },
            { k: 'Lá', kh: 26, t8: 20, t9: 21, lop: 2, di: 0, den: 3 }
          ] },
        { k: 'TH', ten: 'Tiểu học', owner: 'Hiệu trưởng Liên cấp · cấp TH', don: 'PTLC', clbKey: 'TH', hp: 49.6, kh: 980, t5: 936, t8: 897, t9: 897, lop: 38, di: 14, di9: 2, den: 82, den9: 1,
          fmt: { k: 'xls', t: 'Chỉ có trong Excel vận hành' },
          khoi: [
            { k: 'Khối 1', kh: 196, t8: 170, t9: 171, lop: 7, di: 4, den: 48 },
            { k: 'Khối 2', kh: 196, t8: 170, t9: 171, lop: 8, di: 4, den: 7 },
            { k: 'Khối 3', kh: 196, t8: 172, t9: 171, lop: 9, di: 2, den: 14 },
            { k: 'Khối 4', kh: 196, t8: 192, t9: 192, lop: 7, di: 3, den: 13 },
            { k: 'Khối 5', kh: 196, t8: 193, t9: 192, lop: 7, di: 1, den: 15 }
          ] },
        { k: 'THCS', ten: 'THCS', owner: 'Hiệu trưởng Liên cấp · cấp THCS', don: 'PTLC', clbKey: 'TRUNG', hp: 61.7, kh: 841, t5: 786, t8: 799, t9: 799, lop: 28, di: 10, di9: 2, den: 50, den9: 5,
          fmt: { k: 'xls', t: 'Chỉ có trong Excel vận hành' },
          khoi: [
            { k: 'Khối 6', kh: 232, t8: 216, t9: 217, lop: 7, di: 5, den: 53 },
            { k: 'Khối 7', kh: 232, t8: 209, t9: 208, lop: 8, di: 4, den: 8 },
            { k: 'Khối 8', kh: 174, t8: 167, t9: 167, lop: 7, di: 1, den: 10 },
            { k: 'Khối 9', kh: 203, t8: 207, t9: 207, lop: 6, di: 0, den: 9 }
          ] },
        { k: 'THPT', ten: 'THPT', owner: 'Hiệu trưởng Liên cấp · cấp THPT', don: 'PTLC', clbKey: 'TRUNG', hp: 63.6, kh: 480, t5: 407, t8: 444, t9: 443, lop: 16, di: 7, di9: 2, den: 1, den9: 1,
          fmt: { k: 'xls', t: 'Chỉ có trong Excel vận hành' },
          khoi: [
            { k: 'Khối 10', kh: 180, t8: 185, t9: 185, lop: 4, di: 4, den: 10 },
            { k: 'Khối 11', kh: 150, t8: 126, t9: 125, lop: 6, di: 3, den: 12 },
            { k: 'Khối 12', kh: 150, t8: 133, t9: 133, lop: 6, di: 0, den: 12 }
          ] }
      ],
      funnelRaw: {
        PTLC: { ten: 'Liên cấp (TH–THCS–THPT)', hp: 56.6, l8: 30, l9: 23, n8: 9, n9: 4 },
        MNBH: { ten: 'MN Biên Hòa', hp: 37.2, l8: 144, l9: 77, n8: 16, n9: 7 },
        MNLK: { ten: 'MN Long Khánh', hp: 37.2, l8: 185, l9: 61, n8: 8, n9: 10 }
      },
      clb: {
        MNBH: { kh: 120, t9: 77, label: '77/120' },
        MNLK: { kh: 75, t9: 70, label: '70/75' },
        TH: { kh: 300, t9: 353, label: '353/300' },
        TRUNG: { kh: 150, t9: 96, label: '96/150 THCS+THPT' }
      },
      reasons: [
        { k: 'Nơi ở / tiện đưa đón', v: 21 },
        { k: 'Khác (chưa phân loại)', v: 14 },
        { k: 'Kinh tế', v: 10 },
        { k: 'Bệnh', v: 7 },
        { k: 'Định cư & du học', v: 1 }
      ],
      failReasons: [
        { k: 'Không liên lạc được (gọi 3 lần)', v: 348 },
        { k: 'Bé chưa đủ tuổi', v: 19 },
        { k: 'Không đạt điều kiện tuyển sinh', v: 10 },
        { k: 'Không còn nhu cầu', v: 5 },
        { k: 'Chặn Facebook', v: 5 },
        { k: 'Ngoài tuyến xe đưa đón', v: 4 },
        { k: 'Phụ huynh tham khảo trước', v: 3 },
        { k: 'Học phí cao', v: 2 }
      ],
      tvts: [
        { k: 'Thanh Thảo', code: 'A', t8: 187, t9: 61 },
        { k: 'Mỹ Huyền', code: 'B', t8: 117, t9: 84 },
        { k: 'Ny Na', code: 'C', t8: 52, t9: 7 },
        { k: 'Thanh Hằng', code: 'D', t8: 5, t9: 9 },
        { k: 'Hiền Trang', code: 'E', t8: 0, t9: 0 }
      ],
      sources: [
        { k: 'Facebook', ptlc: 26, mnbh: 198 },
        { k: 'Nhận diện thương hiệu', ptlc: 13, mnbh: 5 },
        { k: 'Phụ huynh LHBS', ptlc: 7, mnbh: 5 },
        { k: 'Người quen giới thiệu', ptlc: 4, mnbh: 7 },
        { k: 'Giáo viên/Nhân viên', ptlc: 0, mnbh: 4 },
        { k: 'Đại sứ cung cấp', ptlc: 2, mnbh: 0 },
        { k: 'Zalo', ptlc: 1, mnbh: 2 },
        { k: 'Sự kiện & Trải nghiệm', ptlc: 0, mnbh: 0 }
      ],
      hr: { in8: 11, out8: 3, in9: 16, out9: 14 },
      risks: [
        { level: 'cao', title: 'Dịch tay chân miệng tại MN Trấn Biên', detail: '30 học sinh mắc trong tháng 9, tập trung lớp nhà trẻ Kitty và Bee (cơ sở 2) — 37% lượt qua phòng y tế. Chỉ có dạng ghi chú chữ trong Excel vận hành và slide 6, không có chỉ số hay ngưỡng cảnh báo.', owner: 'Hiệu trưởng MNTB + Y tế', source: 'Excel vận hành (ghi chú y tế) · bc thang 9 mn tb.pptx' },
        { level: 'cao', title: 'Giữ chân học sinh MN Long Khánh', detail: '10 HS rút trong 2 tháng = 8,1% sĩ số T8, gấp 4 lần nhịp KPI 3. Sĩ số mới đạt 77,7% chỉ tiêu. Năm trước báo cáo rút 61% chưa xác minh.', owner: 'Hiệu trưởng MNLK', source: 'Excel vận hành, sheet 1' },
        { level: 'cao', title: 'Chuyển đổi tuyển sinh mầm non thấp', detail: 'MN Biên Hòa 10,4%, MN Long Khánh 7,3% so với đích 30%. 348 lead không liên lạc được sau 3 lần gọi.', owner: 'Marketing – TVTS', source: 'Excel vận hành, sheet 8' },
        { level: 'tb', title: 'Cúm A tại Tiểu học khối 4 và 5', detail: 'Cuối tháng 9 ghi nhận nhiều ca cúm A, cần theo dõi và khử khuẩn. Chưa có số ca cụ thể.', owner: 'Y tế + Hiệu trưởng Liên cấp', source: 'Excel vận hành, ghi chú y tế' },
        { level: 'tb', title: 'Dịch vụ ăn sáng và xe đưa rước giảm', detail: 'Tháng 9 sụt giảm ở cả 2 dịch vụ; báo cáo nêu ảnh hưởng tới sĩ số và doanh thu nhưng chưa có số liệu.', owner: 'Dịch vụ học sinh – Bán trú', source: 'Excel vận hành, ghi chú' },
        { level: 'tb', title: 'Nghỉ việc sớm của nhân sự mới', detail: '14 người nghỉ trong T9; 4 GV đang thử việc và 2 GV mầm non vừa tuyển T8 đã nghỉ. Năm trước turnover 14%.', owner: 'Nhân sự + BGH', source: 'Excel vận hành, sheet 7' },
        { level: 'tb', title: 'CLB bổ trợ dưới chỉ tiêu', detail: 'MN Biên Hòa và Trung học chỉ đạt 64% chỉ tiêu CLB — ảnh hưởng KPI 3.2.1 doanh thu CLB.', owner: 'BGH các cấp', source: 'Excel vận hành, sheet 2' },
        { level: 'tb', title: 'Thiết bị xuống cấp', detail: '79 phiếu sửa chữa T9 (110 ở T8); máy lạnh dẫn đầu 18 phiếu, tập trung khu B và C.', owner: 'CSVC', source: 'Excel vận hành, sheet 6' },
        { level: 'thap', title: 'Tiết dạy bị ảnh hưởng', detail: '144 lượt tiết vắng/dạy thay trong T9, còn 19 tiết chưa dạy bù.', owner: 'Ban Chuyên môn', source: 'Excel vận hành, sheet 3' }
      ],
      strategicKpis: [
        { code: 'KPI 1', short: 'Tuyển sinh 100% công suất', name: 'Tuyển sinh hằng năm đạt 100% công suất của trường', ev: '2.659/3.019 (88,1%) tháng 5; báo cáo trường 2.700', t9: '2.625/2.873 chỉ tiêu (91,4%); chưa có công suất thiết kế', status: 'Chưa đạt', owner: 'Tuyển sinh/MKT + các trường', need: 'Ngày chốt, công suất thiết kế theo lớp/cơ sở' },
        { code: 'KPI 2', short: 'Trúng tuyển ĐH hàng đầu', name: 'Tăng tỷ lệ HS trúng tuyển ĐH hàng đầu qua lộ trình cá nhân hóa', ev: 'Không có kết quả tuyển sinh ĐH', t9: '', status: 'Chưa đủ dữ liệu', owner: 'BGH Liên cấp/Chuyên môn', need: 'Cohort lớp 12, trường mục tiêu, số trúng tuyển' },
        { code: 'KPI 3', short: 'Rút học dưới 10%', name: 'Duy trì tỷ lệ rút dưới 10% số HS đầu năm', ev: 'Hệ thống 7%; MNTB 15%, MNLK 61%', t9: '53 HS lũy kế, 2,0% sĩ số T8; MNLK 8,1%', status: 'Cần xác minh', owner: 'Vận hành/Tuyển sinh + các trường', need: 'Công thức, mẫu số, tách chuyển trường/tốt nghiệp' },
        { code: 'KPI 4', short: 'Giảm 50% thời gian thủ tục', name: 'Giảm 50% thời gian thủ tục hành chính', ev: 'Nhiều quy trình đã số hóa, chưa có baseline', t9: '', status: 'Chưa đủ dữ liệu', owner: 'ICT + chủ quy trình', need: 'Đo trước–sau 5–10 quy trình trọng yếu' },
        { code: 'KPI 5', short: 'Chuyển đổi 30% · hài lòng 90%', name: 'Chuyển đổi quan tâm → nhập học 30% và hài lòng 90%+', ev: '1.840 lead, 259 HS mới (14%); hài lòng 98%', t9: '54/520 lead T8–T9 (10,4%)', status: 'Đạt một phần', owner: 'Marketing/TVTS/CSKH', need: 'Định nghĩa funnel, chi phí/lead, chi phí/nhập học' },
        { code: 'KPI 6', short: 'Thu hút & giữ chân đội ngũ', name: 'Thu hút và giữ chân đội ngũ chất lượng', ev: 'Turnover 14%; chưa định nghĩa "chất lượng"', t9: '+16 / −14 nhân sự T9', status: 'Chưa đủ dữ liệu', owner: 'Nhân sự + BGH', need: 'Công thức, giữ chân nhóm hiệu suất cao, kế thừa' },
        { code: 'KPI 7', short: 'Lợi nhuận gộp 50%', name: 'Tỷ suất lợi nhuận gộp 50% trên doanh thu giáo dục và dịch vụ', ev: 'P&L để trống; biên hàng hóa 19%', t9: '', status: 'Chưa đủ dữ liệu', owner: 'Kế toán + chủ dịch vụ', need: 'P&L theo trường và hoạt động' },
        { code: '1.1.1', short: 'Công nhận quốc tế', name: 'Đạt công nhận quốc tế về chất lượng giáo dục', ev: 'Chưa có kiểm định; ISO 21001 đang chuẩn bị', t9: '', status: 'Chưa đủ dữ liệu', owner: 'HĐQT/BGH/QLCL', need: 'Loại công nhận, tổ chức, lộ trình' },
        { code: '1.1.2', short: 'Chương trình quốc tế', name: 'Tăng HS tham gia chương trình quốc tế không do LHBS chủ trì', ev: 'IAAC, TIMO, NASA Space Apps…; chưa tổng hợp', t9: '', status: 'Đạt một phần', owner: 'Các trường/Chuyên môn', need: 'Số HS duy nhất, baseline' },
        { code: '1.2.1', short: 'HS đạt "Thành thạo" ≥80%', name: 'Tỷ lệ HS đạt mức Thành thạo trở lên ≥80%', ev: 'Chưa có thang năng lực LHBS', t9: 'MNTB: 5 lĩnh vực đạt 79–90% (284–323/358 trẻ)', status: 'Chưa đủ dữ liệu', owner: 'Chuyên môn/QLCL', need: 'Khung năng lực, công cụ đánh giá' },
        { code: '1.2.2', short: 'Hài lòng tiến bộ ≥90%', name: 'Hài lòng của PH về tiến bộ năng lực ≥90%', ev: 'Không có câu hỏi riêng', t9: 'MNTB: hài lòng chung 92% (4,6/5)', status: 'Chưa đủ dữ liệu', owner: 'QLCL/CSKH', need: 'Câu hỏi riêng, cỡ mẫu' },
        { code: '2.1.1', short: 'Sáng kiến GV +10%', name: 'Tăng ≥10% sáng kiến GV được công nhận', ev: 'MNTB 11 sáng kiến; chưa có danh mục hệ thống', t9: '', status: 'Chưa đủ dữ liệu', owner: 'Chuyên môn/HR', need: 'Tiêu chí, danh mục theo năm' },
        { code: '2.1.2', short: 'Dự án đạt giải +5%', name: 'Tăng ≥5% dự án HS đạt giải', ev: 'Tổng giải 101 → 143, chưa tách dự án', t9: '', status: 'Chưa đủ dữ liệu', owner: 'Chuyên môn/Liên cấp', need: 'Phân loại dự án, baseline' },
        { code: '2.2.1', short: 'Trao đổi trong nước – quốc tế', name: 'Tăng trao đổi trong nước và quốc tế do LHBS tổ chức', ev: 'STEMTOPIA 14 trường; giao lưu Nhật Bản', t9: '', status: 'Đạt một phần', owner: 'Đối ngoại/Marketing', need: 'Định nghĩa, số người duy nhất' },
        { code: '2.2.2', short: 'Liên minh STEM +10%', name: 'Đối tác Liên minh STEM tăng ≥10% đến 2030', ev: 'Chưa đủ bằng chứng là đối tác', t9: '', status: 'Chưa đủ dữ liệu', owner: 'Liên minh STEM', need: 'Danh sách baseline, MOU' },
        { code: '3.1.1', short: 'ISO 21001:2018', name: 'Triển khai và đạt ISO 21001:2018', ev: 'Có đội ISO, kế hoạch đánh giá nội bộ', t9: '', status: 'Đang chuẩn bị', owner: 'QLCL–ISO', need: 'Gap assessment, lộ trình, ngân sách' },
        { code: '3.2.1', short: 'Doanh thu CLB STEM', name: 'Tăng doanh thu CLB STEM, Robotics AI, Lập trình, Khoa học', ev: 'Chưa tách doanh thu theo CLB', t9: 'CLB: 596 HS / 645 chỉ tiêu toàn hệ thống', status: 'Chưa đủ dữ liệu', owner: 'Kế toán + CLB', need: 'Mã doanh thu–chi phí theo CLB' },
        { code: '3.2.2', short: '50% du học qua đối tác', name: '50% HS có nguyện vọng du học trúng tuyển qua đối tác', ev: 'Không có dữ liệu', t9: '', status: 'Chưa đủ dữ liệu', owner: 'Liên cấp/Đối ngoại', need: 'Cohort, nguyện vọng, kết quả' }
      ],
      kpiStatusOrder: ['Đạt', 'Đạt một phần', 'Đang chuẩn bị', 'Cần xác minh', 'Chưa đạt', 'Chưa đủ dữ liệu'],
      codeMap: [
        { n: 'Tuyển sinh đạt 100% công suất', m: 'KPI 1', a: 'KPI 1', b: 'KPI 1' },
        { n: 'Trúng tuyển đại học hàng đầu', m: 'KPI 2', a: 'KPI 2', b: 'KPI 2' },
        { n: 'Rút học dưới 10%', m: 'KPI 3', a: 'KPI 3', b: 'KPI 3' },
        { n: 'Giảm 50% thời gian thủ tục', m: 'KPI 4', a: 'KPI 4', b: 'KPI 5' },
        { n: 'Chuyển đổi tuyển sinh 30% và hài lòng 90%', m: 'KPI 5', a: 'KPI 5', b: 'KPI 6' },
        { n: 'Thu hút và giữ chân đội ngũ', m: 'KPI 6', a: 'KPI 6', b: '—' },
        { n: 'Lợi nhuận gộp 50%', m: 'KPI 7', a: 'KPI 7', b: 'KPI 4' },
        { n: 'Hài lòng phụ huynh về tiến bộ học sinh ≥90%', m: 'KPI 1.2.2', a: '1.2.2', b: 'KPI 6 · 1.2.2' }
      ],
      newIssues: [
        { n: 'Dòng sĩ số T8 → T9', a: 'T8 2.616 + 25 đến − 12 đi = 2.629', b: 'Sĩ số T9 báo cáo 2.625', d: 'lệch 4 HS', o: 'Vận hành + các trường' },
        { n: 'Dòng sĩ số theo đơn vị', a: 'T8 + đến − đi: MNBH 361 · MNLK 127 · TH 896 · THCS 802 · THPT 443', b: 'Sĩ số T9: 357 · 129 · 897 · 799 · 443', d: '4/5 đơn vị lệch', o: 'HT các đơn vị' },
        { n: 'HS chuyển đến: theo khối và theo cấp', a: 'Cộng các khối: TH 97 · THCS 80 · THPT 34', b: 'Dòng tổng cấp: TH 82 · THCS 50 · THPT 1', d: 'lệch 78 HS', o: 'Vận hành + HT Liên cấp' },
        { n: 'Lead tháng 8', a: 'Theo tư vấn viên: 361', b: 'Theo đơn vị: 359', d: 'lệch 2 lead', o: 'Marketing – TVTS' },
        { n: 'Sĩ số MN Trấn Biên', a: 'Excel vận hành: 357', b: 'Báo cáo tháng (đánh giá 5 lĩnh vực): 358', d: 'lệch 1 HS', o: 'HT MN Trấn Biên' },
        { n: 'Tên đơn vị', a: 'Excel: "MN Biên Hòa"', b: 'PPTX, tổng kết: "Mầm non Trấn Biên"', d: 'khác tên', o: 'Vận hành' },
        { n: 'Công thức thiếu/vượt chỉ tiêu', a: 'Excel sheet 1, cột W', b: 'Ra −2.873 (tham chiếu tháng chưa có số)', d: 'sai công thức', o: 'Người lập Excel' },
        { n: 'Mã KPI chiến lược', a: 'Bản tổng kết: chuyển đổi = KPI 5', b: 'Tài liệu 19/10: chuyển đổi = KPI 6', d: '4 mã lệch', o: 'Thầy Thái + M&E' }
      ],
      oldIssues: [
        { n: 'Tổng HS cuối năm', d: '2.700 so với 2.659 (chênh 41)' },
        { n: 'MNTB', d: '408 so với 398 trẻ' },
        { n: 'MNLK', d: '122/182 so với 132/173' },
        { n: 'Rút học MNLK', d: 'tái ghi danh 94,6% nhưng rút 61%' },
        { n: 'Kỷ luật/gian lận', d: '0 vụ so với 1 vụ tại MNLK' },
        { n: 'Kết quả THPT', d: '455/131/2121 nghi lỗi định dạng' },
        { n: 'Tốt nghiệp THPT', d: 'chờ kết quả' },
        { n: 'Hài lòng bếp', d: 'chênh 0,1–0,18 điểm' },
        { n: 'CRM', d: 'hoàn thành so với chưa triển khai' },
        { n: 'Phân hệ ngân sách', d: 'hoàn thành so với chờ duyệt' },
        { n: 'Tiêu chuẩn ISO', d: '21000 so với 21001' },
        { n: '20 hệ thống CNTT', d: 'hai cách phân loại' },
        { n: 'KPI lợi nhuận', d: 'không cùng công thức' },
        { n: 'Khảo sát hài lòng', d: 'không có cỡ mẫu' },
        { n: 'Mục tiêu 2026–2027', d: 'Liên cấp chưa có trong báo cáo' }
      ],
      feeds: [
        { n: 'Sĩ số, rút, chuyển đến', now: 'Excel sheet 1, nhập tay theo tháng', sys: 'Quản lý HS (Basic data / ME)', plan: 'Nối tự động – đợt 1', st: 'good' },
        { n: 'Tiết vắng / dạy thay', now: 'Excel sheet 3, xuất rồi dán', sys: 'TKB – Quản lý dạy thay (đã có trong Ký số)', plan: 'Nối tự động – đợt 1', st: 'good' },
        { n: 'Nghỉ phép', now: 'Excel sheet 5, xuất rồi dán', sys: 'HRM', plan: 'Nối tự động – đợt 1', st: 'good' },
        { n: 'Biến động nhân sự', now: 'Excel sheet 7, xuất rồi dán', sys: 'HRM', plan: 'Nối tự động – đợt 1', st: 'good' },
        { n: 'Sửa chữa CSVC', now: 'Excel sheet 6, pivot tay', sys: 'Quản lý tài sản / báo sửa', plan: 'Nối tự động – đợt 1', st: 'good' },
        { n: 'Khám sức khỏe / y tế', now: 'Excel sheet 4 + slide báo cáo tháng', sys: 'Phần mềm y tế (cần xác nhận)', plan: 'Đợt 2', st: 'warn' },
        { n: 'CLB ngoại khóa', now: 'Excel sheet 2, nhập tay', sys: 'Đăng ký CLB / thu phí', plan: 'Đợt 2', st: 'warn' },
        { n: 'Lead, nhập học, lý do', now: 'Excel tracking TVTS', sys: 'CRM (đang phát triển)', plan: 'Chờ CRM', st: 'bad' },
        { n: 'Chuyên cần, giáo dục mầm non', now: 'Slide/PDF, số trong ảnh', sys: 'ME / sổ theo dõi trẻ', plan: 'Mẫu nhập chuẩn', st: 'bad' },
        { n: 'Chi phí, P&L', now: 'Chưa có', sys: 'Kế toán', plan: 'Cần Kế toán', st: 'bad' }
      ],
      decisions: [
        { t: 'Phê duyệt bộ định nghĩa KPI và quy trình quản trị dữ liệu thống nhất', e: 'Gồm công thức, nguồn, ngày chốt, người sở hữu. Liên quan trực tiếp 8 điểm lệch T9 và 4 mã KPI lệch.' },
        { t: 'Ưu tiên nguồn lực tuyển sinh – giữ chân tại THPT và MN Long Khánh', e: 'MNLK đạt 77,7% chỉ tiêu, rút 8,1% sau 2 tháng; THPT khối 11 đạt 83%.' },
        { t: 'Kiện toàn chức năng Quản lý dữ liệu & Đo lường', e: '12/18 KPI chiến lược chưa đo được; 4 định dạng báo cáo khác nhau mỗi tháng.' },
        { t: 'Yêu cầu P&L theo trường và từng dịch vụ', e: 'KPI 7 (lợi nhuận gộp 50%) và KPI 3.2.1 (doanh thu CLB) chưa có dữ liệu; giá trị VNĐ trên dashboard đang là ước tính.' },
        { t: 'Phê duyệt lịch báo cáo tuần/tháng/học kỳ/năm và cơ chế giải trình', e: 'Sự cố y tế (30 ca TCM) cần cơ chế báo ngay, không đợi báo cáo tháng.' }
      ],
      assumptions: [
        { k: 'Học phí/năm (niêm yết 2026, chưa gồm bán trú)', v: 'MN 37,2 · TH 49,6 · THCS 61,7 · THPT 63,6 tr · nguồn: trang học phí lhbs.edu.vn; khớp BC thường niên 2024–25' },
        { k: 'Học phí BQ phễu tuyển sinh', v: 'Liên cấp 56,6 tr (bình quân theo sĩ số) · MN 37,2 tr; kho lead 39,1 tr (theo cơ cấu lead)' },
        { k: 'Tháng học còn lại (từ 01/10)', v: '8 / 9 tháng' },
        { k: 'Biên lợi nhuận góp khi thiếu HS trong lớp đã mở', v: '85%' },
        { k: 'Nhịp đích rút học', v: '10%/năm, tạm chia đều 10 tháng' },
        { k: 'Số năm còn học BQ ở cấp hiện tại (vùng tác động)', v: 'MN 2 · TH 2,5 · THCS 2 · THPT 1,5' },
        { k: 'Tỷ lệ học tiếp lên cấp trên trong hệ thống', v: 'MN→TH 40% · TH→THCS 70% · THCS→THPT 60%' },
        { k: 'Biên LN các năm sau (mô phỏng, ROI)', v: '50% (theo đích KPI 4), chưa chiết khấu' },
        { k: 'Dự báo nền "Thận trọng" (mô phỏng)', v: 'Rút học theo nhịp T9 đến hết năm, không tự có thêm HS' }
      ]
    }
  },

  watch: {
    unit: function (u) {
      if (u === 'MNBH' || u === 'MNLK') this.bm.level = 'MN'
      else if (u === 'TH' || u === 'THCS' || u === 'THPT') this.bm.level = u
    }
  },

  computed: {
    rutPace: function () {
      return this.rutTargetYear * 2 / 10
    },

    all: function () {
      return this.agg(this.units)
    },

    selUnits: function () {
      var u = this.unit
      return this.units.filter(function (x) { return u === 'ALL' || x.k === u })
    },

    m: function () {
      return this.agg(this.selUnits)
    },

    highRiskCount: function () {
      return this.risks.filter(function (r) { return r.level === 'cao' }).length
    },

    topKpis: function () {
      return this.strategicKpis.slice(0, 7)
    },

    funnels: function () {
      var self = this
      return ['PTLC', 'MNBH', 'MNLK'].map(function (k) {
        var f = self.funnelRaw[k]
        var leads = f.l8 + f.l9
        var nh = f.n8 + f.n9
        return { k: k, ten: f.ten, hp: f.hp, leads: leads, nh: nh, conv: leads ? nh / leads : 0,
          c8: f.l8 ? f.n8 / f.l8 : 0, c9: f.l9 ? f.n9 / f.l9 : 0, gapHs: Math.max(0, leads * 0.3 - nh) }
      })
    },

    funnelAll: function () {
      var l = 0, n = 0
      this.funnels.forEach(function (f) { l += f.leads; n += f.nh })
      return { leads: l, nh: n, conv: l ? n / l : 0 }
    },

    mapIn: function () {
      var self = this
      var fun = {}
      self.funnels.forEach(function (f) { fun[f.k] = f })
      var srcOf = function (name) {
        var r = self.sources.filter(function (s) { return s.k === name })[0]
        return r || { ptlc: 0, mnbh: 0 }
      }
      var groups = [
        { id: 'i_fb', label: 'Facebook', keys: ['Facebook'] },
        { id: 'i_br', label: 'Thương hiệu', keys: ['Nhận diện thương hiệu'] },
        { id: 'i_ref', label: 'Giới thiệu', keys: ['Phụ huynh LHBS', 'Người quen giới thiệu', 'Giáo viên/Nhân viên', 'Đại sứ cung cấp'] },
        { id: 'i_za', label: 'Zalo, sự kiện', keys: ['Zalo', 'Sự kiện & Trải nghiệm'] }
      ]
      var lkFb = 232
      var nodes = [], links = []
      var tot = { PTLC: 0, MNBH: 0 }
      groups.forEach(function (g) {
        var p = 0, b = 0
        g.keys.forEach(function (k) { p += srcOf(k).ptlc; b += srcOf(k).mnbh })
        var l = g.id === 'i_fb' ? lkFb : 0
        tot.PTLC += p; tot.MNBH += b
        g.p = p; g.b = b; g.l = l
        nodes.push({ id: g.id, col: 0, label: g.label, tone: 'src',
          note: g.label + ': ' + self.fmtInt(p + b + l) + ' lead (Liên cấp ' + p + ', MN Biên Hòa ' + b + ', MN Long Khánh ' + l + ')' + (g.keys.length > 1 ? '. Gồm: ' + g.keys.join(', ') + '.' : '.') })
        links.push({ s: g.id, t: 'i_PTLC', v: p, tone: 'src' }, { s: g.id, t: 'i_MNBH', v: b, tone: 'src' }, { s: g.id, t: 'i_MNLK', v: l, tone: 'src' })
      })
      var naP = fun.PTLC.leads - tot.PTLC, naB = fun.MNBH.leads - tot.MNBH, naL = fun.MNLK.leads - lkFb
      nodes.push({ id: 'i_na', col: 0, label: 'Chưa ghi nguồn', tone: 'na', note: 'Lead không ghi kênh nguồn: ' + (naP + naB + naL) + ' (chủ yếu MN Long Khánh, chỉ ghi Facebook ' + lkFb + '/' + fun.MNLK.leads + ').' })
      links.push({ s: 'i_na', t: 'i_PTLC', v: naP, tone: 'na' }, { s: 'i_na', t: 'i_MNBH', v: naB, tone: 'na' }, { s: 'i_na', t: 'i_MNLK', v: naL, tone: 'na' })

      var fr = function (arr, k) { var r = arr.filter(function (x) { return x.k === k })[0]; return r ? r.v : 0 }
      var kllKey = 'Không liên lạc được (gọi 3 lần)'
      var res = {}
      var pFail = 0
      self.failPtlc.forEach(function (x) { pFail += x.v })
      res.PTLC = { nh: fun.PTLC.nh, kll: fr(self.failPtlc, kllKey), oth: pFail - fr(self.failPtlc, kllKey), est: false }
      res.PTLC.care = fun.PTLC.leads - fun.PTLC.nh - pFail
      var mnFail = self.failTotal, mnKll = fr(self.failReasons, kllKey)
      var openB = fun.MNBH.leads - fun.MNBH.nh, openL = fun.MNLK.leads - fun.MNLK.nh
      var failB = Math.round(mnFail * openB / (openB + openL)), failL = mnFail - failB
      var kllB = Math.round(mnKll * failB / mnFail), kllL = mnKll - kllB
      res.MNBH = { nh: fun.MNBH.nh, kll: kllB, oth: failB - kllB, care: openB - failB, est: true }
      res.MNLK = { nh: fun.MNLK.nh, kll: kllL, oth: failL - kllL, care: openL - failL, est: true }

      var uName = { PTLC: 'Liên cấp', MNBH: 'MN Biên Hòa', MNLK: 'MN Long Khánh' }
      var st = { nh: 0, kll: 0, oth: 0, care: 0 }
      var uKeys = ['PTLC', 'MNBH', 'MNLK']
      uKeys.forEach(function (k) {
        var r = res[k], f = fun[k]
        nodes.push({ id: 'i_' + k, col: 1, label: uName[k], tone: 'unit',
          note: uName[k] + ': ' + f.leads + ' lead → ' + r.nh + ' nhập học (' + self.fmtPct(f.conv, 1) + '), ' + r.care + ' đang chăm sóc, ' + (r.kll + r.oth) + ' rơi' + (r.est ? ' (phần rơi là ước tính phân bổ từ tổng Mầm non)' : '') + '.' })
        links.push({ s: 'i_' + k, t: 'i_nh', v: r.nh, tone: 'good' },
          { s: 'i_' + k, t: 'i_care', v: r.care, tone: 'care', est: r.est },
          { s: 'i_' + k, t: 'i_oth', v: r.oth, tone: 'na', est: r.est },
          { s: 'i_' + k, t: 'i_kll', v: r.kll, tone: 'bad', est: r.est })
        st.nh += r.nh; st.kll += r.kll; st.oth += r.oth; st.care += r.care
      })
      nodes.push(
        { id: 'i_nh', col: 2, label: 'Nhập học', tone: 'good', note: 'Nhập học T8–T9: ' + st.nh + ' học sinh, chuyển đổi ' + self.fmtPct(st.nh / self.funnelAll.leads, 1) + ' (đích 30%). Dữ liệu thật.' },
        { id: 'i_care', col: 2, label: 'Đang chăm sóc', tone: 'care', note: 'Đang chăm sóc: ' + st.care + ' lead, suy ra bằng lead − nhập học − rơi. Còn chốt được trong năm.' },
        { id: 'i_oth', col: 2, label: 'Rơi · lý do khác', tone: 'na', note: 'Rơi vì lý do khác: ' + st.oth + ' (chưa đủ tuổi, không đạt điều kiện, hết nhu cầu, chặn Facebook, ngoài tuyến xe, tham khảo, học phí).' },
        { id: 'i_kll', col: 2, label: 'Rơi · không liên lạc được', tone: 'bad', note: 'Không liên lạc được sau 3 lần gọi: ' + self.fmtInt(st.kll) + ' lead = ' + self.fmtPct(st.kll / self.funnelAll.leads, 0) + ' tổng lead. Đây là kho lead lớn nhất còn khai thác được.' }
      )
      var fbAll = groups[0].p + groups[0].b + groups[0].l
      var refAll = groups[2].p + groups[2].b + groups[2].l
      return { nodes: nodes, links: links, total: self.funnelAll.leads, nh: st.nh, kll: st.kll, other: st.oth, care: st.care, fb: fbAll, ref: refAll,
        heads: ['Kênh nguồn', 'Đơn vị', 'Kết quả'] }
    },

    mapInS: function () {
      return this.sankey(this.mapIn.nodes, this.mapIn.links, this.mapIn.heads, 960, 290, 136, 196)
    },

    mapOut: function () {
      var self = this
      var nodes = [], links = []
      var short = { MNBH: 'MN Biên Hòa', MNLK: 'MN Long Khánh', TH: 'Tiểu học', THCS: 'THCS', THPT: 'THPT' }
      var total = 0
      self.units.forEach(function (u) {
        total += u.di
        nodes.push({ id: 'o_' + u.k, col: 0, label: short[u.k], tone: 'unit', note: short[u.k] + ': ' + u.di + ' học sinh rút lũy kế, riêng T9 ' + u.di9 + ' em. Dữ liệu thật.' })
        links.push({ s: 'o_' + u.k, t: 'o_rut', v: u.di, tone: 'out' })
      })
      nodes.push({ id: 'o_rut', col: 1, label: 'Rút học', tone: 'out', note: 'Tổng ' + total + ' học sinh rút. Lý do mới có tổng toàn hệ thống, chưa tách theo đơn vị.' })
      var noiO = 0, khac = 0
      self.reasons.forEach(function (r, i) {
        var isKhac = r.k.indexOf('Khác') === 0
        if (r.k.indexOf('Nơi ở') === 0) noiO = r.v
        if (isKhac) khac = r.v
        nodes.push({ id: 'o_r' + i, col: 2, label: r.k, tone: isKhac ? 'na' : 'out', note: r.k + ': ' + r.v + '/' + total + ' ca (' + self.fmtPct(r.v / total, 0) + ').' + (isKhac ? ' Cần phỏng vấn rời trường để phân loại lại.' : '') })
        links.push({ s: 'o_rut', t: 'o_r' + i, v: r.v, tone: isKhac ? 'na' : 'out' })
        links.push({ s: 'o_r' + i, t: 'o_na', v: r.v, tone: 'na' })
      })
      nodes.push({ id: 'o_na', col: 3, label: 'Chưa ghi trường đến', tone: 'na', note: 'Chưa ca nào ghi trường chuyển đến (0/' + total + '). Chưa biết đang mất học sinh cho đối thủ nào.' })
      var ph = ['Trường công lập', 'Trường tư thục khác', 'Tỉnh khác / nước ngoài', 'Nghỉ ở nhà / bảo lưu']
      ph.forEach(function (t, i) {
        nodes.push({ id: 'o_p' + i, col: 3, label: t, ph: true, tone: 'ph', note: t + ': chưa có dữ liệu. Phiếu rút hồ sơ cần ghi trường chuyển đến để tách ô này.' })
      })
      return { nodes: nodes, links: links, total: total, noiO: noiO, khac: khac, heads: ['Đơn vị', 'Rút học', 'Lý do', 'Nơi đến'] }
    },

    mapOutS: function () {
      return this.sankey(this.mapOut.nodes, this.mapOut.links, this.mapOut.heads, 960, 250, 132, 180)
    },

    mapS: function () {
      return this.map.flow === 'out' ? this.mapOutS : this.mapInS
    },

    mapActive: function () {
      if (this.map.hover) return this.map.hover
      var u = this.unit
      if (u === 'ALL') return ''
      if (this.map.flow === 'out') return 'o_' + u
      return 'i_' + (u === 'TH' || u === 'THCS' || u === 'THPT' ? 'PTLC' : u)
    },

    mapHatch: function () {
      return [{ k: 'bad', c: '#d13438' }, { k: 'care', c: '#3A6EA5' }, { k: 'na', c: '#8a8886' }]
    },

    mapStats: function () {
      var a = this.mapIn, o = this.mapOut
      return [
        { k: 'Lead T8–T9', v: this.fmtInt(a.total), d: 'Facebook ' + this.fmtPct(a.fb / a.total, 0) + ' · giới thiệu ' + this.fmtPct(a.ref / a.total, 0), flow: 'in', focus: 'i_fb', cls: '' },
        { k: 'Nhập học', v: a.nh, u: this.fmtPct(a.nh / a.total, 1), d: 'Đích 30% · thiếu ' + this.fmtInt(this.mapGap) + ' HS', flow: 'in', focus: 'i_nh', cls: 'st-l-bad' },
        { k: 'Lead rơi', v: this.fmtInt(a.kll + a.other), d: this.fmtInt(a.kll) + ' không liên lạc được · ' + a.other + ' lý do khác', flow: 'in', focus: 'i_kll', cls: 'st-l-bad' },
        { k: 'Đang chăm sóc', v: a.care, d: 'Suy ra: lead − nhập học − rơi', flow: 'in', focus: 'i_care', cls: '' },
        { k: 'Rút học (lũy kế)', v: o.total, d: o.noiO + ' vì nơi ở / đưa đón · ' + o.khac + ' chưa rõ', flow: 'out', focus: 'o_rut', cls: '' },
        { k: 'Đã ghi trường đến', v: 0, u: '/ ' + o.total, d: 'Khoảng trống dữ liệu', flow: 'out', focus: 'o_na', cls: 'is-gap' }
      ]
    },

    mapHl: function () {
      var h = this.mapActive
      var set = {}
      if (!h) return set
      var links = this.mapIn.links.concat(this.mapOut.links)
      set[h] = true
      var walk = function (from, dir) {
        var q = [from]
        while (q.length) {
          var c = q.shift()
          links.forEach(function (l) {
            if (l.v <= 0) return
            var a = dir > 0 ? l.s : l.t, b = dir > 0 ? l.t : l.s
            if (a === c && !set[b + dir]) { set[b + dir] = true; set[b] = true; q.push(b) }
          })
        }
      }
      walk(h, 1)
      walk(h, -1)
      return set
    },

    mapGap: function () {
      var g = 0
      this.funnels.forEach(function (f) { g += f.gapHs })
      return g
    },

    mapPool: function () {
      var self = this
      var fr = function (k) {
        var a = self.failReasons.filter(function (x) { return x.k === k })[0]
        var b = self.failPtlc.filter(function (x) { return x.k === k })[0]
        return (a ? a.v : 0) + (b ? b.v : 0)
      }
      var rows = [
        { k: 'care', t: 'Đang chăm sóc, chưa chốt', when: 'Chốt được năm nay', n: self.mapIn.care, who: 'Tư vấn viên', act: 'Hẹn tham quan, trải nghiệm trong 30 ngày', src: 'uoc' },
        { k: 'kll', t: 'Không liên lạc được sau 3 lần gọi', when: 'Chốt được năm nay', n: self.mapIn.kll, who: 'Tư vấn viên + Marketing', act: 'Gọi lại khung giờ khác, chuyển Zalo/SMS, remarketing; đo thời gian phản hồi lead đầu', src: 'that' },
        { k: 'age', t: 'Bé chưa đủ tuổi', when: 'Nguồn cho năm sau', n: fr('Bé chưa đủ tuổi'), who: 'Tư vấn viên', act: 'Đưa vào danh sách nuôi dưỡng, hẹn lại theo tháng sinh', src: 'that', next: true },
        { k: 'ref', t: 'Phụ huynh tham khảo trước', when: 'Chốt được năm nay', n: fr('Phụ huynh tham khảo trước'), who: 'Tư vấn viên', act: 'Mời tham quan trong 7 ngày', src: 'that' },
        { k: 'bus', t: 'Ngoài tuyến xe đưa đón', when: 'Chốt được năm nay', n: fr('Ngoài tuyến xe đưa đón'), who: 'Bán trú – Xe đưa rước', act: 'Gom theo cụm địa chỉ, xét mở điểm đón', src: 'that' },
        { k: 'fee', t: 'Học phí cao', when: 'Chốt được năm nay', n: fr('Học phí cao'), who: 'Kế toán – Chính sách', act: 'Gói chia kỳ, ưu đãi anh chị em', src: 'that' },
        { k: 'out', t: 'Không phù hợp', when: 'Không đạt điều kiện, hết nhu cầu, chặn Facebook', n: fr('Không đạt điều kiện tuyển sinh') + fr('Không còn nhu cầu') + fr('Chặn Facebook'), who: 'Marketing', act: 'Loại khỏi kho; dùng để lọc chất lượng quảng cáo', src: 'that', fixed: true }
      ]
      rows.forEach(function (r) {
        var rate = r.fixed ? 0 : Math.min(100, Math.max(0, Number(self.map.rec[r.k]) || 0)) / 100
        r.hs = r.n * rate
        r.rev = r.next ? 0 : r.hs * self.mapHp * self.remain
      })
      return rows
    },

    mapPoolSum: function () {
      var s = { n: 0, hs: 0, rev: 0 }
      this.mapPool.forEach(function (r) {
        if (r.fixed || r.next) return
        s.n += r.n; s.hs += r.hs; s.rev += r.rev
      })
      return s
    },

    mapFeeder: function () {
      var self = this
      var t9 = function (uk, kk) {
        var u = self.units.filter(function (x) { return x.k === uk })[0]
        var r = u ? u.khoi.filter(function (x) { return x.k === kk })[0] : null
        return r ? r.t9 : 0
      }
      var la = self.lifeAssume
      return [
        { k: 'mn', t: 'Lá → Lớp 1', sub: 'Mầm non → Tiểu học', base: t9('MNBH', 'Lá') + t9('MNLK', 'Lá'), p: self.feedRate('mn'), nhp: la.MNBH.nhp },
        { k: 'th', t: 'Lớp 5 → Lớp 6', sub: 'Tiểu học → THCS', base: t9('TH', 'Khối 5'), p: self.feedRate('th'), nhp: la.TH.nhp },
        { k: 'thcs', t: 'Lớp 9 → Lớp 10', sub: 'THCS → THPT', base: t9('THCS', 'Khối 9'), p: self.feedRate('thcs'), nhp: la.THCS.nhp }
      ]
    },

    feedSum: function () {
      var t = { base: 0, up: 0, rev: 0, plus5: 0 }
      this.mapFeeder.forEach(function (f) {
        t.base += f.base
        t.up += f.base * f.p
        t.rev += f.base * f.p * f.nhp
        t.plus5 += f.base * 0.05
      })
      return t
    },

    mapK1Den: function () {
      var u = this.units.filter(function (x) { return x.k === 'TH' })[0]
      var r = u ? u.khoi.filter(function (x) { return x.k === 'Khối 1' })[0] : null
      return r ? r.den : 0
    },

    mapBusLead: function () {
      var r = this.failReasons.filter(function (x) { return x.k === 'Ngoài tuyến xe đưa đón' })[0]
      return r ? r.v : 0
    },

    mapReadyCount: function () {
      var c = { co: 0, mot: 0, chua: 0 }
      this.mapReady.forEach(function (r) { if (r.st === 'good') c.co++; else if (r.st === 'part') c.mot++; else c.chua++ })
      return c
    },

    bmLevel: function () {
      return this.bm.level
    },

    bmLevelName: function () {
      var l = this.bm.level
      var o = this.bmLevels.filter(function (x) { return x.k === l })[0]
      return o ? o.t : l
    },

    bmRows: function () {
      var self = this, L = this.bm.level
      var lhbsHs = { MN: 0, TH: 0, THCS: 0, THPT: 0 }
      self.units.forEach(function (u) {
        var key = u.k === 'MNBH' || u.k === 'MNLK' ? 'MN' : u.k
        lhbsHs[key] += u.t9
      })
      return self.bmSchools.map(function (p) {
        var lvHas = p.lv.indexOf(L) >= 0
        var has = lvHas && p.fee[L] !== undefined && p.fee[L] !== null
        return { k: p.k, t: p.t, short: p.short, self: !!p.self, area: p.area, lv: p.lv, prog: p.prog, vs: p.vs,
          lvHas: lvHas, has: has, fee: has ? p.fee[L] : 0, feeSrc: p.feeSrc, feeNote: p.feeNote, q: p.q,
          hs: p.self ? lhbsHs[L] : (p.hs && p.hs[L] ? p.hs[L] : 0), hsSrc: p.self ? 'that' : (p.hsSrc || 'gia'), hsNote: p.hsNote || '' }
      })
    },

    bmPeers: function () {
      return this.bmRows.filter(function (r) { return r.has && !r.self })
    },

    bmSelf: function () {
      return this.bmRows.filter(function (r) { return r.self })[0]
    },

    bmMed: function () {
      var med = function (arr) {
        var a = arr.slice().sort(function (x, y) { return x - y })
        if (!a.length) return 0
        var m = Math.floor(a.length / 2)
        return a.length % 2 ? a[m] : (a[m - 1] + a[m]) / 2
      }
      var P = this.bmPeers
      return { fee: med(P.map(function (r) { return r.fee })), q: med(P.map(function (r) { return r.q })), hs: med(P.map(function (r) { return r.hs })) }
    },

    bmCount: function () {
      var c = { cong: 0, tong: 0, gia: 0 }
      c.none = 0
      this.bmRows.forEach(function (r) {
        if (r.has) c[r.feeSrc] = (c[r.feeSrc] || 0) + 1
        else if (r.lvHas) c.none++
      })
      return c
    },

    bmMap: function () {
      var W = 600, H = 330, L = 58, T = 12, R = 16, B = 36
      var pw = W - L - R, ph = H - T - B
      var pts = this.bmRows.filter(function (r) { return r.has })
      var fmin = 1e9, fmax = 0, hmax = 1
      pts.forEach(function (r) { fmin = Math.min(fmin, r.fee); fmax = Math.max(fmax, r.fee); hmax = Math.max(hmax, r.hs) })
      var lo = Math.log(fmin * 0.8), hi = Math.log(fmax * 1.25)
      var sx = function (v) { return L + (Math.log(v) - lo) / (hi - lo) * pw }
      var ylo = 55, yhi = 92
      var sy = function (v) { return T + ph - (v - ylo) / (yhi - ylo) * ph }
      var xt = [20, 30, 50, 70, 100, 150, 200, 300, 500, 700, 1000].filter(function (v) { return Math.log(v) >= lo && Math.log(v) <= hi }).map(function (v) { return { v: v, x: sx(v) } })
      var yt = [60, 70, 80, 90].map(function (v) { return { v: v, y: sy(v) } })
      var out = pts.map(function (r) {
        var x = sx(r.fee), y = sy(r.q), rad = 5 + Math.sqrt(r.hs / hmax) * 14
        return { k: r.k, short: r.short, self: r.self, feeSrc: r.feeSrc, hs: r.hs, x: x, y: y, r: rad, la: 'start', lx: x + rad + 4, ly: y + 4 }
      })
      var boxes = []
      var hitBox = function (b) {
        if (b.x < L + 2 || b.x + b.w > L + pw - 2 || b.y < T + 14 || b.y + b.h > T + ph - 12) return true
        if (boxes.some(function (o) { return b.x < o.x + o.w && b.x + b.w > o.x && b.y < o.y + o.h && b.y + b.h > o.y })) return true
        return out.some(function (c) {
          var cx = Math.max(b.x, Math.min(c.x, b.x + b.w)), cy = Math.max(b.y, Math.min(c.y, b.y + b.h))
          return (cx - c.x) * (cx - c.x) + (cy - c.y) * (cy - c.y) < c.r * c.r * 0.7
        })
      }
      out.slice().sort(function (a, b) { return (b.self ? 1e6 : b.hs) - (a.self ? 1e6 : a.hs) }).forEach(function (o) {
        var w = o.short.length * 6.6 + 4, h = 14
        var cands = []
        var dys = [0, -14, 14, -28, 28, -42, 42, -56, 56]
        dys.forEach(function (dy) {
          cands.push({ la: 'start', lx: o.x + o.r + 4, ly: o.y + 4 + dy, b: { x: o.x + o.r + 4, y: o.y - 9 + dy, w: w, h: h } })
          cands.push({ la: 'end', lx: o.x - o.r - 4, ly: o.y + 4 + dy, b: { x: o.x - o.r - 4 - w, y: o.y - 9 + dy, w: w, h: h } })
          if (dy === 0) {
            cands.push({ la: 'middle', lx: o.x, ly: o.y - o.r - 4, b: { x: o.x - w / 2, y: o.y - o.r - 16, w: w, h: h } })
            cands.push({ la: 'middle', lx: o.x, ly: o.y + o.r + 12, b: { x: o.x - w / 2, y: o.y + o.r + 2, w: w, h: h } })
          }
        })
        var pick = cands.filter(function (c) { return !hitBox(c.b) })[0] || cands[0]
        o.la = pick.la
        o.lx = pick.lx
        o.ly = pick.ly
        o.lead = Math.abs(pick.ly - 4 - o.y) > 14 && pick.la !== 'middle' ? { x1: o.x + (pick.la === 'start' ? o.r * 0.7 : -o.r * 0.7), y1: o.y, x2: pick.lx + (pick.la === 'start' ? -2 : 2), y2: pick.ly - 4 } : null
        boxes.push(pick.b)
      })
      var mx = sx(this.bmMed.fee), my = sy(this.bmMed.q)
      return { W: W, H: H, L: L, T: T, pw: pw, ph: ph, xt: xt, yt: yt, pts: out, mx: mx, my: my,
        quads: [
          { t: 'Đáng tiền', x: L + 6, y: T + 12, a: 'start' },
          { t: 'Cao cấp', x: L + pw - 6, y: T + 12, a: 'end' },
          { t: 'Cạnh tranh bằng giá', x: L + 6, y: T + ph - 6, a: 'start' },
          { t: 'Giá cao, đầu ra chưa tương xứng', x: L + pw - 6, y: T + ph - 6, a: 'end' }
        ] }
    },

    bmHoverRow: function () {
      var h = this.bm.hover
      if (!h) return null
      return this.bmRows.filter(function (r) { return r.k === h && r.has })[0] || null
    },

    bmRank: function () {
      var self = this, S = this.bmSelf, P = this.bmPeers, M = this.bmMed
      var mk = function (k, t, sub, get, log, fmt) {
        var vals = P.map(get).concat([get(S)])
        var mn = Math.min.apply(null, vals), mx = Math.max.apply(null, vals)
        var f = log ? function (v) { return Math.log(Math.max(v, 1)) } : function (v) { return v }
        var a = f(mn), b = f(mx)
        var pos = function (v) { return b > a ? 4 + (f(v) - a) / (b - a) * 92 : 50 }
        var pv = P.map(get)
        return { k: k, t: t, sub: sub, minP: pos(Math.min.apply(null, pv)), maxP: pos(Math.max.apply(null, pv)), medP: pos(M[k]), selfP: pos(get(S)), selfTxt: fmt(get(S)), medTxt: fmt(M[k]) }
      }
      return [
        mk('fee', 'Học phí', 'triệu đồng/năm, thang log', function (r) { return r.fee }, true, function (v) { return self.fmtInt(v) }),
        mk('hs', 'Quy mô', 'học sinh ở cấp này', function (r) { return r.hs }, false, function (v) { return self.fmtInt(v) }),
        mk('q', 'Đầu ra', 'chỉ số giả định 0–100', function (r) { return r.q }, false, function (v) { return self.fmtInt(v) })
      ]
    },

    bmTable: function () {
      return this.bmRows.slice().sort(function (a, b) {
        if (a.self !== b.self) return a.self ? -1 : 1
        if (a.has !== b.has) return a.has ? -1 : 1
        return b.fee - a.fee
      })
    },

    bmLoss: function () {
      var tot = this.mapOut.total
      var rows = this.bmLossRaw.map(function (r) { var raw = r.s * tot; return { k: r.k, t: r.t, n: Math.floor(raw), rem: raw - Math.floor(raw) } })
      var left = tot
      rows.forEach(function (r) { left -= r.n })
      rows.slice().sort(function (a, b) { return b.rem - a.rem }).slice(0, left).forEach(function (r) { r.n += 1 })
      return rows
    },

    bmLossMax: function () {
      var m = 1
      this.bmLoss.forEach(function (r) { if (r.n > m) m = r.n })
      return m
    },

    rfHeadline: function () {
      var c = this.kpiCount
      var has = c['Đạt'] + c['Đạt một phần']
      var nx = this.cutUpcoming[0]
      return this.strategicKpis.length + ' KPI chiến lược: ' + has + ' có kết quả (đạt hoặc đạt một phần), ' + c['Chưa đạt'] + ' chưa đạt, ' +
        (c['Đang chuẩn bị'] + c['Cần xác minh']) + ' đang chuẩn bị hoặc cần xác minh, ' + c['Chưa đủ dữ liệu'] + ' chưa đủ dữ liệu để đo. ' +
        'Baseline 2020–2025 mới thu được ' + this.rfStats.base + '%' + (nx ? '; kỳ chốt kế tiếp ' + nx.d + ' (' + nx.codes.length + ' KPI).' : '.')
    },

    boardHeadline: function () {
      var a = this.all
      var weak = this.unitRows.filter(function (r) { return r.pct < 0.9 }).map(function (r) { return r.ten.split(' (')[0] })
      return 'Sĩ số đạt ' + this.fmtPct(a.pct, 1) + ' chỉ tiêu, còn thiếu ' + this.fmtInt(a.gap) + ' học sinh (≈ ' + this.fmtTy(a.vGap) + ' doanh thu năm học)' +
        (weak.length ? ', tập trung ở ' + weak.join(', ') : '') + '. Điểm nghẽn lớn nhất là chuyển đổi tuyển sinh ' + this.fmtPct(this.funnelAll.conv, 1) + ' so với đích 30%.'
    },

    boardTiles: function () {
      var self = this
      return [
        self.tileSiso(self.all, function () { self.openImpact(self.boardWorst, 'siso') }),
        self.tileRev(self.units, self.all, function () { self.openImpact(self.boardWorst, 'siso') }),
        self.tileRut(self.all, true, function () { self.openImpact('MNLK', 'rut') }),
        self.tileConv(function () { self.openImpact('MNBH', 'conv') })
      ]
    },

    qmTiles: function () {
      var self = this
      var u = self.unit
      return [
        self.tileSiso(self.m, function () { self.openImpact(u, 'siso') }),
        self.tileRev(self.selUnits, self.m, function () { self.openImpact(u, 'siso') }),
        self.tileRut(self.m, u === 'ALL', function () { self.openImpact(u) }),
        self.tileNet(self.m)
      ]
    },

    funnelMonth: function () {
      var r = { l8: 0, l9: 0, n8: 0, n9: 0 }
      var raw = this.funnelRaw
      Object.keys(raw).forEach(function (k) { r.l8 += raw[k].l8; r.l9 += raw[k].l9; r.n8 += raw[k].n8; r.n9 += raw[k].n9 })
      r.c8 = r.l8 ? r.n8 / r.l8 : 0
      r.c9 = r.l9 ? r.n9 / r.l9 : 0
      return r
    },

    tsTiles: function () {
      var self = this
      var f = self.funnelAll
      var fm = self.funnelMonth
      var py = self.prevYear
      var khNh = Math.round(f.leads * 0.3)
      var f0 = self.failReasons[0]
      var fr = f0.v / self.failTotal
      return [
        { k: 'Lead mới T8–T9', v: self.fmtInt(f.leads), st: 'none', d: 'Liên cấp, MN Biên Hòa, MN Long Khánh · theo tháng phát sinh',
          sp: self.spark([fm.l8, fm.l9], ['T8', 'T9'], [self.fmtInt(fm.l8), self.fmtInt(fm.l9)], null),
          cmp: self.cmpRow(self.fmtInt(f.leads), '2.900/năm', '—', '', self.fmtInt(py.leads)) },
        { k: 'Học sinh nhập học mới', v: self.fmtInt(f.nh), st: self.statusConv(f.conv), d: 'Kế hoạch tính theo mức chuyển đổi 30% trên số lead',
          sp: self.spark([fm.n8, fm.n9], ['T8', 'T9'], [fm.n8, fm.n9], null),
          cmp: self.cmpRow(self.fmtInt(f.nh), self.fmtInt(khNh), self.signed(f.nh - khNh, 0), f.nh >= khNh ? 'is-good' : 'is-bad', self.fmtInt(py.nh)) },
        self.tileConv(function () { self.openImpact('MNBH', 'conv') }),
        { k: 'Lead không liên lạc được', v: self.fmtPct(fr, 0), st: fr > 0.5 ? 'bad' : (fr > 0.3 ? 'warn' : 'good'), d: f0.v + '/' + self.failTotal + ' lead thất bại (mầm non) · học phí chỉ ' + self.failHocPhi + ' trường hợp',
          sp: null,
          cmp: self.cmpRow(self.fmtInt(f0.v), '—', '—', '', '—') }
      ]
    },

    qmHeadline: function () {
      var m = this.m
      var r0 = this.reasons[0]
      return this.unitLabel(this.unit) + ': sĩ số đạt ' + this.fmtPct(m.pct, 1) + ' chỉ tiêu, thiếu ' + this.fmtInt(m.gap) + ' học sinh (≈ ' + this.fmtTy(m.vGap) + ' doanh thu còn lại). ' +
        'Rút lũy kế ' + this.fmtPct(m.rut, 1) + ' so với nhịp cho phép ' + this.fmtPct(this.rutPace, 1) + ', ròng vào – ra ' + this.signed(m.den - m.di, 0) + ' HS. ' +
        'Toàn hệ thống, ' + this.fmtPct(r0.v / this.reasonTotal, 0) + ' trường hợp rút vì ' + r0.k.toLowerCase() + '.'
    },

    tsHeadline: function () {
      var f = this.funnelAll
      var f0 = this.failReasons[0]
      return 'Chuyển đổi T8–T9 đạt ' + this.fmtPct(f.conv, 1) + ' (' + f.nh + '/' + f.leads + ' lead), thấp hơn đích 30% và mức cả năm học trước ' + this.fmtPct(this.prevYear.conv, 1) + '. ' +
        this.fmtPct(f0.v / this.failTotal, 0) + ' lead thất bại vì ' + f0.k.toLowerCase() + '; học phí chỉ là lý do của ' + this.failHocPhi + ' trường hợp. ' +
        'Hai tư vấn viên đang xử lý ' + this.fmtPct(this.tvtsTop2, 0) + ' lead.'
    },

    covGroups: function () {
      var self = this
      var kw = { TS: [], YT: ['tay chân miệng', 'Cúm'], BA: ['ăn sáng'], TC: ['CLB'] }
      return ['TS', 'YT', 'BA', 'TC'].map(function (k) {
        var meta = self.dictGroups.filter(function (x) { return x.k === k })[0]
        var items = self.kpiDict.filter(function (d) { return d.g === k })
        var c = { good: 0, part: 0, none: 0 }
        items.forEach(function (d) { c[d.rd]++ })
        var sig = self.risks.filter(function (r) { return kw[k].some(function (w) { return r.title.indexOf(w) >= 0 }) })
        return { k: k, t: meta.t, items: items, good: c.good, part: c.part, none: c.none, sig: sig }
      })
    },

    covHeadline: function () {
      var g = this.covGroups
      var tot = { good: 0, part: 0, none: 0 }
      g.forEach(function (x) { tot.good += x.good; tot.part += x.part; tot.none += x.none })
      var ops = g.filter(function (x) { return x.k !== 'TS' })
      var opsHas = 0
      var opsN = 0
      ops.forEach(function (x) { opsHas += x.good; opsN += x.items.length })
      return this.kpiDict.length + ' chỉ số vận hành theo phương án 19/10: ' + tot.good + ' có dữ liệu, ' + tot.part + ' có một phần, ' + tot.none + ' chưa có nguồn. ' +
        'Nhóm tuyển sinh sẵn nhất; an toàn – y tế, bếp ăn – bán trú và tài chính có ' + opsHas + '/' + opsN + ' chỉ số đo được đầy đủ, các tín hiệu rủi ro T9 của các nhóm này mới ở dạng ghi chú chữ. ' +
        'Tất cả định nghĩa còn ở trạng thái nháp, đa số vẫn nhập tay.'
    },

    boardRisks: function () {
      return this.risks.filter(function (r) { return r.level === 'cao' }).slice(0, 3).map(function (r) {
        var imp = null
        if (r.title.indexOf('Long Khánh') >= 0) imp = { u: 'MNLK', t: 'rut' }
        else if (r.title.indexOf('Chuyển đổi') >= 0) imp = { u: 'MNBH', t: 'conv' }
        return { title: r.title, detail: r.detail, owner: r.owner, imp: imp }
      })
    },

    boardWorst: function () {
      var w = null
      this.unitRows.forEach(function (r) { if (!w || (r.kh - r.t9) > (w.kh - w.t9)) w = r })
      return w ? w.k : 'MNLK'
    },

    boardExplain: function () {
      return this.unitRows.filter(function (r) { return r.mustExplain }).map(function (r) { return r.ten.split(' (')[0] })
    },

    rfRows: function () {
      var q = (this.dict.q || '').trim().toLowerCase()
      return this.rfDict.filter(function (k) {
        return !q || (k.c + ' ' + k.n + ' ' + k.owner).toLowerCase().indexOf(q) >= 0
      })
    },

    rfSel: function () {
      var c = this.dict.selD
      return this.rfDict.filter(function (k) { return k.c === c })[0] || null
    },

    rfSystem: function () {
      return this.rfDict.filter(function (k) { return k.out === 'HT' })
    },

    rfStats: function () {
      var self = this
      var s = { total: self.rfDict.length, noOwner: 0, noVerify: 0, base: 0, noBase: 0, review: 0, linked: 0 }
      var sum = 0
      self.rfDict.forEach(function (k) {
        if (k.owner === 'Chưa điền') s.noOwner++
        if (k.verify === 'Chưa điền') s.noVerify++
        if (k.review.length) s.review++
        sum += self.rfBase(k.c)
        if ((self.rfBaseline[k.c] || []).some(function (b) { return b.nb })) s.noBase++
      })
      s.base = Math.round(sum / Math.max(1, s.total))
      s.linked = self.kpiDict.filter(function (d) { return d.rfk }).length
      return s
    },

    cutRows: function () {
      var self = this
      var get = function (c) { return self.rfDict.filter(function (k) { return k.c === c })[0] }
      return [
        { c: 'KPI 1', n: 'Tuyển sinh đạt 100% công suất', v: self.fmtPct(self.all.pct, 1), vn: 'Sĩ số / kế hoạch năm học', def: '(HS mới + HS cũ) / công suất thiết kế; phụ: HS mới nhập học / chỉ tiêu HS mới', need: 'Công suất thiết kế (phòng khả dụng × sĩ số chuẩn); chỉ tiêu HS mới; tách HS mới và HS cũ', next: self.rfNext(get('KPI 1')) },
        { c: 'KPI 3', n: 'Rút học dưới 10%', v: self.fmtPct(self.all.rut, 1), vn: 'Rút lũy kế / sĩ số tháng 8', def: 'HS rút trong năm / HS đầu năm (1/8); kèm chuyển cấp và tăng giảm ròng', need: 'Lý do theo 6 nhóm của MASTER; nơi chuyển đi; HS chuyển đến đầu cấp', next: self.rfNext(get('KPI 3')) },
        { c: 'KPI 5', n: 'Chuyển đổi 30% và hài lòng 90%', v: self.fmtPct(self.funnelAll.conv, 1), vn: 'Lead T8–T9 → nhập học', def: 'HS nhập học mới / inquiry theo chiến dịch; hài lòng ≥90% tính riêng', need: 'Dữ liệu theo chiến dịch: chi phí, nguồn inquiry (Website, Hotline, Event, Giới thiệu, Khác); khảo sát hài lòng', next: self.rfNext(get('KPI 5')) }
      ]
    },

    cutUpcoming: function () {
      var self = this
      var by = {}
      var out = []
      self.rfDict.forEach(function (k) {
        var n = self.rfNext(k)
        if (!n.t) return
        if (!by[n.d]) { by[n.d] = { d: n.d, t: n.t, days: n.days, codes: [] }; out.push(by[n.d]) }
        by[n.d].codes.push(k.c)
      })
      return out.sort(function (a, b) { return a.t - b.t }).slice(0, 4)
    },

    tierInfo: function () {
      return this.tierPages[this.page] || { k: '', lead: '', show: [], pre: [] }
    },

    isAnalysisPage: function () {
      var n = this.page
      return this.pages.some(function (p) { return p.n === n && p.grp === 'pt' })
    },

    dictRows: function () {
      var g = this.dict.grp, q = (this.dict.q || '').trim().toLowerCase()
      return this.kpiDict.filter(function (d) {
        if (g !== 'ALL' && d.g !== g) return false
        if (!q) return true
        return (d.c + ' ' + d.n + ' ' + d.src + ' ' + d.own).toLowerCase().indexOf(q) >= 0
      })
    },

    dictSel: function () {
      var c = this.dict.sel
      return this.kpiDict.filter(function (d) { return d.c === c })[0] || null
    },

    dictStats: function () {
      var s = { total: 0, full: 0, tay: 0, goalTay: 0, goalAuto: 0, good: 0, part: 0, none: 0, duyet: 0, add: 0 }
      this.kpiDict.forEach(function (d) {
        s.total++
        if (d.num && d.rule && d.cut && d.src) s.full++
        if (d.now === 'tay') s.tay++
        if (d.goal === 'tay') s.goalTay++
        else s.goalAuto++
        s[d.rd]++
        if (d.st === 'duyet') s.duyet++
        if (d.add) s.add++
      })
      return s
    },

    dictFlow: function () {
      var d = this.dictSel
      if (!d) return []
      var hasData = d.rd !== 'none'
      return [
        { t: 'Nguồn dữ liệu', who: d.src, st: hasData ? 'done' : 'todo' },
        { t: 'Chủ sở hữu xác nhận', who: d.own, st: hasData ? 'doing' : 'todo' },
        { t: 'Kiểm tra', who: d.chk, st: d.st === 'kt' || d.st === 'duyet' ? 'done' : 'todo' },
        { t: 'Phê duyệt định nghĩa', who: d.apr, st: d.st === 'duyet' ? 'done' : 'todo' },
        { t: 'Hiển thị', who: d.used, st: d.used.indexOf('Chưa') === 0 ? 'todo' : 'doing' }
      ]
    },

    opsGroups: function () {
      var self = this
      var kw = { YT: ['tay chân miệng', 'Cúm'], BA: ['ăn sáng'], TC: ['CLB'] }
      return ['YT', 'BA', 'TC'].map(function (k) {
        var meta = self.dictGroups.filter(function (x) { return x.k === k })[0]
        var items = self.kpiDict.filter(function (d) { return d.g === k })
        var sig = self.risks.filter(function (r) { return kw[k].some(function (w) { return r.title.indexOf(w) >= 0 }) })
        return { k: k, t: meta.t, en: meta.en, items: items, sig: sig,
          ready: items.filter(function (d) { return d.rd !== 'none' }).length,
          manual: items.filter(function (d) { return d.now === 'tay' }).length }
      })
    },

    opsTotal: function () {
      var n = 0
      this.opsGroups.forEach(function (g) { n += g.items.length })
      return n
    },

    opsSignalCount: function () {
      var n = 0
      this.opsGroups.forEach(function (g) { n += g.sig.length })
      return n
    },

    funnelMax: function () {
      var mx = 1
      this.funnels.forEach(function (f) { if (f.leads > mx) mx = f.leads })
      return mx
    },

    unitRows: function () {
      var self = this
      return self.units.map(function (u) {
        var a = self.agg([u])
        var f = null
        self.funnels.forEach(function (x) { if (x.k === u.don) f = x })
        var cl = self.clb[u.clbKey]
        var fn = { conv: f.conv, label: u.don === 'PTLC' ? 'PTLC gộp' : f.nh + '/' + f.leads }
        var row = Object.assign({}, u, a, { fn: fn, clbPct: cl.t9 / cl.kh, clbLabel: cl.label })
        row.mustExplain = self.statusPct(a.pct) === 'bad' || self.statusRut(a) === 'bad' || self.statusConv(fn.conv) === 'bad'
        return row
      })
    },

    weakUnitsText: function () {
      var self = this
      var weak = self.unitRows.filter(function (r) { return r.pct < 0.9 })
      if (!weak.length) return ''
      return weak.length + '/5 đơn vị dưới 90%: ' + weak.map(function (r) { return r.ten.split(' (')[0] + ' ' + self.fmtPct(r.pct, 1) }).join(', ') + '.'
    },

    wf: function () {
      var self = this
      var rows = this.selUnits
      var m = this.m
      var steps = [{ lines: ['Chỉ tiêu', 'NH 26–27'], v: m.kh, type: 'total' }]
      var list = []
      if (rows.length === 1) {
        rows[0].khoi.forEach(function (k) { list.push({ lines: [k.k], gap: k.kh - k.t9, hp: rows[0].hp }) })
      } else {
        rows.forEach(function (r) {
          var lines = r.k === 'MNBH' ? ['MN', 'Biên Hòa'] : (r.k === 'MNLK' ? ['MN', 'Long Khánh'] : [r.ten])
          list.push({ lines: lines, gap: r.kh - r.t9, hp: r.hp })
        })
      }
      list.forEach(function (x) {
        steps.push({ lines: x.lines, v: -x.gap, money: x.gap > 0 ? x.gap * x.hp * self.remain : 0 })
      })
      steps.push({ lines: ['Thực tế', 'T9'], v: m.t9, type: 'end' })
      var cum = 0
      var pts = []
      steps.forEach(function (s) {
        if (!s.type) s.type = s.v < 0 ? 'down' : 'up'
        var a, b
        if (s.type === 'total' || s.type === 'end') { a = 0; b = s.v; cum = s.v } else { a = cum; b = cum + s.v; cum = b }
        pts.push({ a: a, b: b })
      })
      var hi = Math.max(m.kh, m.t9) * 1.03
      var lo = Math.min(m.kh, m.t9) * 0.9
      var step = this.niceStep((hi - lo) / 4)
      lo = Math.floor(lo / step) * step
      hi = Math.ceil(hi / step) * step
      var top = 18, bot = 222
      var yOf = function (v) { return bot - (Math.max(v, lo) - lo) / (hi - lo) * (bot - top) }
      var slot = (630 - 56) / steps.length
      var bw = slot * 0.56
      var bars = steps.map(function (s, i) {
        var p = pts[i]
        var y1 = yOf(Math.max(p.a, p.b))
        var y2 = yOf(Math.min(p.a, p.b))
        if (s.type === 'total' || s.type === 'end') { y1 = yOf(p.b); y2 = bot }
        var money = ''
        if (s.money) money = '−' + self.fmtTy(s.money)
        return { x: 56 + i * slot + (slot - bw) / 2, w: bw, y: y1, h: Math.max(1.5, y2 - y1), endY: yOf(p.b), type: s.type, lines: s.lines, money: money,
          text: (s.type === 'up' ? '+' : (s.type === 'down' ? '−' : '')) + self.fmtInt(Math.abs(s.v)) }
      })
      var ticks = []
      for (var t = lo; t <= hi + 0.1; t += step) ticks.push({ v: t, y: yOf(t) })
      var conns = []
      for (var i = 0; i < bars.length - 1; i++) conns.push({ x1: bars[i].x + bars[i].w, x2: bars[i + 1].x, y: bars[i].endY })
      return { bars: bars, ticks: ticks, conns: conns }
    },

    detailRows: function () {
      var self = this
      var rows = []
      if (self.unit === 'ALL') {
        self.units.forEach(function (u) {
          rows.push({ k: u.k, ten: u.ten, kh: u.kh, t5: u.t5, t8: u.t8, t9: u.t9, lop: u.lop, di: u.di, den: u.den, hp: u.hp, pct: u.t9 / u.kh, drill: true })
        })
        var a = self.all
        rows.push({ k: 'T', ten: 'Toàn hệ thống', kh: a.kh, t5: a.t5, t8: a.t8, t9: a.t9, lop: a.lop, di: a.di, den: a.den, hp: a.hpAvg, pct: a.pct, total: true, vGap: a.vGap })
      } else {
        var u = self.selUnits[0]
        u.khoi.forEach(function (k) {
          rows.push({ k: k.k, ten: k.k, kh: k.kh, t5: null, t8: k.t8, t9: k.t9, lop: k.lop, di: k.di, den: k.den, hp: u.hp, pct: k.t9 / k.kh })
        })
        rows.push({ k: 'T', ten: 'Cộng ' + u.ten, kh: u.kh, t5: u.t5, t8: u.t8, t9: u.t9, lop: u.lop, di: u.di, den: u.den, hp: u.hp, pct: u.t9 / u.kh, total: true, vGap: self.agg([u]).vGap })
      }
      rows.forEach(function (r) { if (r.vGap === undefined) r.vGap = Math.max(0, r.kh - r.t9) * r.hp * self.remain })
      var mx = 1
      rows.forEach(function (r) { if (!r.total) mx = Math.max(mx, r.kh, r.t9) })
      rows.forEach(function (r) { r.scale = r.total ? Math.max(r.kh, r.t9) : mx })
      return rows
    },

    reasonTotal: function () {
      var s = 0
      this.reasons.forEach(function (r) { s += r.v })
      return s
    },

    failTotal: function () {
      var s = 0
      this.failReasons.forEach(function (r) { s += r.v })
      return s
    },

    failHocPhi: function () {
      var v = 0
      this.failReasons.forEach(function (r) { if (r.k === 'Học phí cao') v = r.v })
      return v
    },

    tvtsTotal: function () {
      var s = 0
      this.tvts.forEach(function (t) { s += t.t8 + t.t9 })
      return s || 1
    },

    tvtsTop2: function () {
      var arr = this.tvts.map(function (t) { return t.t8 + t.t9 }).sort(function (a, b) { return b - a })
      return (arr[0] + arr[1]) / this.tvtsTotal
    },

    kpiCount: function () {
      var c = {}
      this.kpiStatusOrder.forEach(function (s) { c[s] = 0 })
      this.strategicKpis.forEach(function (k) { c[k.status] = (c[k.status] || 0) + 1 })
      return c
    },

    kpisFiltered: function () {
      var f = this.kpiFilter
      return this.strategicKpis.filter(function (k) { return f === 'all' || k.status === f })
    },

    flowRows: function () {
      var self = this
      var per = self.flowPeriod
      var months = per === 'cum' ? 2 : 1
      var rows = self.units.map(function (u) {
        var vin, vout, base
        if (per === 't9') { vin = u.den9; vout = u.di9; base = u.t8 }
        else if (per === 't8') { vin = u.den - u.den9; vout = u.di - u.di9; base = u.t8 - vin + vout }
        else { vin = u.den; vout = u.di; base = u.t9 - u.den + u.di }
        return Object.assign({ k: u.k, ten: u.ten.split(' (')[0] }, self.flowOf(base, vin, vout, months))
      })
      var b = 0, i = 0, o = 0
      rows.forEach(function (r) { b += r.base; i += r.vin; o += r.vout })
      rows.push(Object.assign({ k: 'ALL', ten: 'Toàn hệ thống', total: true }, self.flowOf(b, i, o, months)))
      return rows
    },

    flowT9: function () {
      var self = this
      var out = {}
      self.units.forEach(function (u) { out[u.k] = self.flowOf(u.t8, u.den9, u.di9, 1) })
      return out
    },

    FQ: function () {
      var xMax = 4, yMax = 3.5
      var X = function (v) { return 50 + Math.sqrt(Math.min(Math.max(v, 0), xMax) / xMax) * 360 }
      var Y = function (v) { return 290 - Math.min(v, 3.3) / yMax * 280 }
      var maxB = 1
      var rows = this.flowRows.filter(function (r) { return !r.total })
      rows.forEach(function (r) { if (r.base > maxB) maxB = r.base })
      var dots = rows.map(function (r) {
        return { k: r.k, label: r.ten.replace('MN ', 'MN '), v: r.v, x: X(r.pace ? r.rate / r.pace : 0), y: Y(r.vout ? r.repl : 3), r: 6 + 12 * Math.sqrt(r.base / maxB) }
      })
      dots.forEach(function (d) {
        var w = d.label.length * 6
        var right = d.x + d.r + 4
        var hitRight = d.x > 300 || dots.some(function (o) { return o !== d && o.x > d.x && o.x - o.r < right + w && Math.abs(o.y - d.y) < o.r + 8 })
        if (!hitRight) { d.lx = right; d.lyy = d.y + 4; d.la = 'start' }
        else {
          var hitLeft = d.x - d.r - 4 - w < 50 || dots.some(function (o) { return o !== d && o.x < d.x && o.x + o.r > d.x - d.r - 4 - w && Math.abs(o.y - d.y) < o.r + 8 })
          if (!hitLeft) { d.lx = d.x - d.r - 4; d.lyy = d.y + 4; d.la = 'end' }
          else { d.lx = d.x; d.lyy = d.y - d.r - 5; d.la = 'middle' }
        }
      })
      var xticks = [0.5, 1, 2, 4].map(function (t) { return { t: t, x: X(t) } })
      return { xMid: X(1), yMid: Y(1), dots: dots, xticks: xticks }
    },

    quickCheck: function () {
      var self = this
      var u = null
      self.units.forEach(function (x) { if (x.k === self.quick.unit) u = x })
      var f = self.flowOf(u.t9, self.quick.vin || 0, self.quick.vout || 0, self.quick.months)
      var times = f.pace ? f.rate / f.pace : 0
      var why = ''
      if (f.v === 'xau') why = 'Rút ' + self.fmtPct(f.rate, 1) + ' trong ' + self.quick.months + ' tháng, gấp ' + self.fmtNum(times, 1) + ' lần nhịp cho phép; mỗi học sinh rời đi chỉ bù được ' + self.fmtNum(f.repl, 2) + ' học sinh. Đơn vị vừa giữ chân kém vừa thu hẹp.'
      else if (f.v === 'bu') why = 'Sĩ số không giảm nhờ tuyển mới, nhưng rút ' + self.fmtPct(f.rate, 1) + ' (gấp ' + self.fmtNum(times, 1) + ' lần nhịp). Giữ chân có vấn đề và đang phải trả chi phí tuyển bù.'
      else if (f.v === 'thieu') why = 'Giữ chân trong nhịp cho phép, nhưng số vào ít hơn số ra nên sĩ số giảm ' + Math.abs(f.net) + ' học sinh. Cần đẩy tuyển bổ sung.'
      else why = 'Rút trong nhịp cho phép và số vào bù đủ số ra.'
      f.why = why
      f.money = f.net * u.hp * self.remain
      return f
    },

    simFunnels: function () {
      var self = this
      return ['PTLC', 'MNBH', 'MNLK'].map(function (k) {
        var f = self.funnelRaw[k]
        return { k: k, short: k === 'PTLC' ? 'Liên cấp' : (k === 'MNBH' ? 'MN Biên Hòa' : 'MN Long Khánh'), l9: f.l9, c9: f.l9 ? f.n9 / f.l9 : 0 }
      })
    },

    simBase: function () {
      var st = JSON.parse(JSON.stringify(this.sim))
      ;['lead', 'conv', 'keep', 'add', 'cost'].forEach(function (g) { Object.keys(st[g]).forEach(function (x) { st[g][x] = 0 }) })
      return this.simCalc(st)
    },

    simCur: function () {
      return this.simCalc(this.sim)
    },

    activeTvts: function () {
      return this.tvts.filter(function (t) { return t.t8 + t.t9 > 0 }).length || 1
    },

    simFlags: function () {
      var self = this
      var out = []
      self.simFunnels.forEach(function (f) {
        var c = f.c9 + (self.sim.conv[f.k] || 0) / 100
        if (c > 0.3) out.push(f.short + ': chuyển đổi ' + self.fmtPct(c, 0) + ' vượt mức cao nhất từng đạt')
        if ((self.sim.lead[f.k] || 0) >= 60) out.push(f.short + ': lead +' + self.sim.lead[f.k] + '% cần tăng mạnh ngân sách')
      })
      self.simCur.units.forEach(function (u) { if (u.end > u.cap) out.push(u.ten.split(' (')[0] + ': vượt sức chứa lớp ước tính, cần mở lớp') })
      if (self.simCur.leads / self.activeTvts > 60) out.push('Mỗi tư vấn viên > 60 lead/tháng — cần thêm người')
      return out
    },

    explainDiff: function () {
      var b = this.simBase.units, c = this.simCur.units
      var out = [], inn = []
      c.forEach(function (u, i) {
        if (b[i].explain && !u.explain) out.push(u.ten.split(' (')[0])
        if (!b[i].explain && u.explain) inn.push(u.ten.split(' (')[0])
      })
      if (!out.length && !inn.length) return 'Không đổi so với dự báo nền'
      return (out.length ? 'Thoát: ' + out.join(', ') : '') + (out.length && inn.length ? ' · ' : '') + (inn.length ? 'Rơi vào: ' + inn.join(', ') : '')
    },

    simSummary: function () {
      var c = this.simCur, b = this.simBase
      var s = [
        { t: 'Kịch bản đưa sĩ số cuối năm từ ' + this.fmtPct(b.pct, 1) + ' lên ' }, { t: this.fmtPct(c.pct, 1), b: true }, { t: ' chỉ tiêu (' + this.signed(c.end - b.end, 0) + ' HS), tạo ' },
        { t: this.signTy(c.dLn) + ' LN góp năm nay', b: true }, { t: ' và ' }, { t: this.signTy(c.dLtv) + ' LN các năm sau', b: true }, { t: '. ' }
      ]
      if (c.cost) s.push({ t: 'Với chi phí ' + this.fmtTy(c.cost) + ', giá trị ròng ' }, { t: this.signTy(c.net), b: true }, { t: ' (ROI năm nay ' + this.fmtNum(c.roiYear, 1) + '×, cả vòng đời ' + this.fmtNum(c.roi, 1) + '×), hoàn vốn ' + c.payback + '. ' })
      s.push({ t: 'Đơn vị phải giải trình: ' }, { t: b.explain + ' → ' + c.explain, b: true }, { t: '. KPI 3 rút cả năm ' + this.fmtPct(b.rutYear, 1) + ' → ' + this.fmtPct(c.rutYear, 1) + '.' })
      if (this.simFlags.length) s.push({ t: ' Lưu ý khả thi: ' + this.simFlags.length + ' cảnh báo.' })
      return s
    },

    simBridge: function () {
      var self = this
      var c = this.simCur
      var steps = [
        { lines: ['Dự báo', 'nền'], v: c.endBase, type: 'total' },
        { lines: ['Chuyển', 'đổi'], v: c.contrib.conv, money: c.lnContrib.conv },
        { lines: ['Lead'], v: c.contrib.lead, money: c.lnContrib.lead },
        { lines: ['Giữ', 'chân'], v: c.contrib.keep, money: c.lnContrib.keep },
        { lines: ['Tuyển', 'bổ sung'], v: c.contrib.add, money: c.lnContrib.add },
        { lines: ['Kịch', 'bản'], v: c.end, type: 'end' }
      ]
      var cum = 0
      var pts = []
      steps.forEach(function (s) {
        if (!s.type) s.type = s.v < 0 ? 'down' : 'up'
        var a, bb
        if (s.type === 'total' || s.type === 'end') { a = 0; bb = s.v; cum = s.v } else { a = cum; bb = cum + s.v; cum = bb }
        pts.push({ a: a, b: bb })
      })
      var hi = Math.max(c.kh, c.end, c.endBase) * 1.03
      var lo = Math.min(c.kh, c.end, c.endBase) * 0.92
      var step = this.niceStep((hi - lo) / 4)
      lo = Math.floor(lo / step) * step
      hi = Math.ceil(hi / step) * step
      var top = 18, bot = 222
      var yOf = function (v) { return bot - (Math.max(v, lo) - lo) / (hi - lo) * (bot - top) }
      var slot = (630 - 56) / steps.length
      var bw = slot * 0.56
      var bars = steps.map(function (s, i) {
        var p = pts[i]
        var y1 = yOf(Math.max(p.a, p.b))
        var y2 = yOf(Math.min(p.a, p.b))
        if (s.type === 'total' || s.type === 'end') { y1 = yOf(p.b); y2 = bot }
        var money = (s.money !== undefined && Math.abs(s.money) >= 1) ? self.signTy(s.money) : ''
        return { x: 56 + i * slot + (slot - bw) / 2, w: bw, y: y1, h: Math.max(1.5, y2 - y1), endY: yOf(p.b), type: s.type, lines: s.lines, money: money,
          text: (s.type === 'up' ? '+' : (s.type === 'down' ? '−' : '')) + self.fmtInt(Math.abs(s.v)) }
      })
      var ticks = []
      for (var t = lo; t <= hi + 0.1; t += step) ticks.push({ v: t, y: yOf(t) })
      var conns = []
      for (var i = 0; i < bars.length - 1; i++) conns.push({ x1: bars[i].x + bars[i].w, x2: bars[i + 1].x, y: bars[i].endY })
      return { bars: bars, ticks: ticks, conns: conns, planY: yOf(c.kh) }
    },

    simGoal: function () {
      var self = this
      var c = this.simCur
      var need = Math.max(0, Math.ceil(this.sim.target * c.kh - c.end))
      var M = c.M
      var perPt = 0, perPct = 0
      ;['PTLC', 'MNBH', 'MNLK'].forEach(function (k) {
        var f = self.funnelRaw[k]
        var c9 = f.l9 ? f.n9 / f.l9 : 0
        var L = (self.sim.lead[k] || 0) / 100
        var D = (self.sim.conv[k] || 0) / 100
        perPt += M * f.l9 * (1 + L) * 0.01
        perPct += M * f.l9 * 0.01 * (c9 + D)
      })
      var remainRut = 0
      c.units.forEach(function (u, i) { var b = self.units[i]; remainRut += (self.sim.mode !== 'hold' ? b.di9 * M : 0) * (1 - (self.sim.keep[b.k] || 0) / 100) })
      var hpAvg = 0
      self.units.forEach(function (u) { hpAvg += u.hp * u.kh })
      hpAvg = hpAvg / c.kh
      var opts = []
      if (need > 0) {
        opts.push({ k: 'Chỉ tăng chuyển đổi (mọi đơn vị)', v: perPt ? '+' + self.fmtNum(need / perPt, 1) + ' điểm %' : '—', ok: perPt && need / perPt <= 15 })
        opts.push({ k: 'Chỉ tăng lead (mọi đơn vị)', v: perPct ? '+' + self.fmtInt(need / perPct) + '%' : '—', ok: perPct && need / perPct <= 100 })
        opts.push({ k: 'Chỉ giữ chân thêm', v: need <= remainRut ? 'giữ thêm ' + self.fmtInt(need) + '/' + self.fmtInt(remainRut) + ' HS dự kiến rút' : 'không đủ (tối đa ' + self.fmtInt(remainRut) + ' HS)', ok: need <= remainRut })
        opts.push({ k: 'Chỉ tuyển bổ sung', v: '+' + self.fmtInt(need) + ' HS', ok: true })
      }
      return { need: need, value: need * hpAvg * ((c.M / 2) / 9) * self.mInc, options: opts }
    },

    compareRows: function () {
      var self = this
      return [
        { k: 'KPI 1 · sĩ số cuối năm', f: function (o) { return self.fmtPct(o.pct, 1) } },
        { k: 'KPI 3 · rút cả năm', f: function (o) { return self.fmtPct(o.rutYear, 1) } },
        { k: 'KPI 5 · chuyển đổi (nhịp T9)', f: function (o) { return self.fmtPct(o.conv, 1) } },
        { k: 'LN góp năm nay', f: function (o) { return self.signTy(o.dLn) } },
        { k: 'LN các năm sau (biên 50%)', f: function (o) { return self.signTy(o.dLtv) } },
        { k: 'Chi phí', f: function (o) { return o.cost ? '−' + self.fmtTy(o.cost) : '—' } },
        { k: 'Giá trị ròng', f: function (o) { return self.signTy(o.net) } },
        { k: 'ROI năm nay', f: function (o) { return o.cost ? self.fmtNum(o.roiYear, 1) + '×' : '—' } },
        { k: 'ROI cả vòng đời', f: function (o) { return o.cost ? self.fmtNum(o.roi, 1) + '×' : '—' } },
        { k: 'Đơn vị phải giải trình', f: function (o) { return o.explain + '/5' } },
        { k: 'Lead cần mỗi tháng', f: function (o) { return self.fmtInt(o.leads) } }
      ]
    },

    reasonsInline: function () {
      return this.reasons.map(function (r) { return r.k + ' ' + r.v }).join(' · ')
    },

    icRut: function () {
      var self = this
      var u = null
      self.units.forEach(function (x) { if (x.k === self.impact.unit) u = x })
      var n = Math.max(1, Math.min(self.impact.n, u.t9))
      var mo = self.monthOptions[0]
      self.monthOptions.forEach(function (o) { if (o.m === self.impact.month) mo = o })
      var route = self.reasonRoutes[self.impact.reason]
      var u1 = Object.assign({}, u, { t9: u.t9 - n, di: u.di + n })
      var a0 = self.agg([u])
      var a1 = self.agg([u1])
      var all0 = self.all
      var all1 = self.agg(self.units.map(function (x) { return x.k === u.k ? u1 : x }))
      var fn = null
      self.funnels.forEach(function (x) { if (x.k === u.don) fn = x })
      var explain = function (a) { return self.statusPct(a.pct) === 'bad' || self.statusRut(a) === 'bad' || self.statusConv(fn.conv) === 'bad' }
      var ex0 = explain(a0)
      var paceR = self.rutTargetYear / 10 * mo.since
      var ex1 = self.statusPct(a1.pct) === 'bad' || a1.rut > paceR * 1.3 || self.statusConv(fn.conv) === 'bad'
      var rutYear = a1.rut >= self.rutTargetYear

      var ring1 = [
        { k: 'Sĩ số ' + u.ten, from: self.fmtInt(a0.t9), to: self.fmtInt(a1.t9), src: 'that' },
        { k: 'Đạt chỉ tiêu', from: self.fmtPct(a0.pct, 1), to: self.fmtPct(a1.pct, 1), src: 'that', flag: self.statusPct(a0.pct) !== self.statusPct(a1.pct) },
        { k: 'Còn thiếu so với chỉ tiêu', from: self.fmtInt(a0.gap) + ' HS', to: self.fmtInt(a1.gap) + ' HS', src: 'that' },
        { k: 'Rút lũy kế (KPI 3)', from: a0.di + ' HS · ' + self.fmtPct(a0.rut, 1), to: a1.di + ' HS · ' + self.fmtPct(a1.rut, 1), src: 'that', flag: rutYear,
          note: rutYear ? 'Vượt đích cả năm (10%) chỉ sau ' + mo.since + ' tháng' : 'Đích cả năm 10%' },
        { k: 'Sĩ số bình quân/lớp', from: self.fmtNum(a0.t9 / u.lop, 1), to: self.fmtNum(a1.t9 / u.lop, 1), src: 'that', note: u.lop + ' lớp' },
        { k: 'Toàn hệ thống: sĩ số', from: self.fmtInt(all0.t9) + ' · ' + self.fmtPct(all0.pct, 1), to: self.fmtInt(all1.t9) + ' · ' + self.fmtPct(all1.pct, 1), src: 'that' },
        { k: 'Toàn hệ thống: rút lũy kế', from: self.fmtPct(all0.rut, 1), to: self.fmtPct(all1.rut, 1), src: 'that' },
        { k: 'Trạng thái đơn vị trên bảng Hội đồng', from: ex0 ? 'Cần giải trình' : 'Theo dõi', to: ex1 ? 'Cần giải trình' : 'Theo dõi', src: 'that', flag: ex1 && !ex0, note: self.explainWhy(a1, fn.conv, paceR) }
      ]

      var revNow = n * u.hp * mo.r
      var groupT9 = 0
      self.units.forEach(function (x) { if (x.clbKey === u.clbKey) groupT9 += x.t9 })
      var cl = self.clb[u.clbKey]
      var clbLost = n * cl.t9 / groupT9
      var ring2 = [
        { k: 'Doanh thu học phí còn lại năm nay', v: '−' + self.fmtTy(revNow), src: 'uoc', bad: true, note: 'Học phí BQ ' + self.fmtNum(u.hp, 1) + ' tr/năm (niêm yết 2026) × ' + Math.round(mo.r * 9) + '/9 tháng' },
        { k: 'Lợi nhuận góp mất', v: '−' + self.fmtTy(revNow * self.mInc), src: 'uoc', bad: true, note: 'Lớp vẫn mở, chi phí giáo viên không giảm' },
        { k: 'Câu lạc bộ ngoại khóa', v: '≈ −' + self.fmtInt(clbLost) + ' học viên', src: 'uoc', note: 'Theo tỷ lệ tham gia CLB của đơn vị · ' + cl.label + ' → ' + self.fmtNum(cl.t9 - clbLost, 0) + '/' + cl.kh },
        { k: 'Bán trú, xe đưa rước, đồng phục', v: 'Chưa tính được', src: 'chua', note: 'Cần nối thu phí dịch vụ theo mã học sinh' },
        { k: 'Chi phí tuyển sinh đã bỏ ra', v: 'Chưa tính được', src: 'chua', note: 'Chưa có chi phí tuyển sinh (CAC) từ Kế toán' }
      ]

      var la = self.lifeAssume[u.k]
      var ltvFuture = n * (Math.max(0, la.yrs - 1) * u.hp + la.p * la.ny * la.nhp)
      var leadsNeed = fn.conv > 0 ? n / fn.conv : 0
      var leadsMonth = fn.leads / 2
      var ref = self.referral[u.don]
      var ring3 = [
        { k: 'Doanh thu các năm học sau', v: '≈ −' + self.fmtTy(ltvFuture), src: 'uoc', bad: true,
          note: 'Còn ~' + self.fmtNum(la.yrs, 1) + ' năm ở cấp này' + (la.p ? '; ' + self.fmtPct(la.p, 0) + ' học tiếp lên ' + la.nl : '') },
        { k: 'Lead cần thêm để tuyển bù', v: '≈ ' + self.fmtInt(leadsNeed) + ' lead', src: 'that', bad: true,
          note: 'Chuyển đổi hiện tại ' + self.fmtPct(fn.conv, 1) + ' · bằng ' + self.fmtPct(leadsNeed / leadsMonth, 0) + ' lượng lead một tháng' },
        { k: 'Kênh giới thiệu', v: ref === null ? 'Chưa tính được' : self.fmtPct(ref, 0) + ' lead đến từ giới thiệu', src: ref === null ? 'chua' : 'that',
          note: 'Phụ huynh rời đi thường không còn giới thiệu; đây là kênh chuyển đổi tốt nhất' },
        { k: 'Anh chị em đang học trong hệ thống', v: 'Chưa tính được', src: 'chua', note: 'Chưa có dữ liệu quan hệ gia đình theo mã học sinh' }
      ]

      var who = [
        { o: u.owner, a: route.unknown ? 'Giải trình tại kỳ họp; phỏng vấn phụ huynh, phân loại lý do chuẩn rồi giao xử lý' : 'Giải trình tại kỳ họp; phỏng vấn phụ huynh trước khi duyệt rút hồ sơ' },
        { o: 'Tuyển sinh – TVTS', a: 'Bổ sung khoảng ' + self.fmtInt(leadsNeed) + ' lead vào kế hoạch để tuyển bù' },
        { o: 'Kế toán', a: 'Cập nhật dự báo doanh thu và khoản hoàn phí (nếu có)' }
      ]
      if (!route.unknown) who.splice(1, 0, { o: route.owner, a: route.act + ' (lý do: ' + route.k + ')' })

      var sum = [
        { t: n + ' học sinh không phải "−' + n + ' trên sĩ số": là ' }, { t: self.fmtTy(revNow), b: true }, { t: ' doanh thu năm nay, khoảng ' },
        { t: self.fmtTy(ltvFuture), b: true }, { t: ' doanh thu các năm sau, và ' }, { t: self.fmtInt(leadsNeed) + ' lead', b: true }, { t: ' phải tìm thêm để bù.' }
      ]
      if (ex1 && !ex0) sum.push({ t: ' ' + u.ten + ' ' }, { t: 'chuyển sang "Cần giải trình"', b: true }, { t: '.' })
      sum.push({ t: ' Chịu trách nhiệm giải trình: ' }, { t: u.owner, b: true }, { t: '.' })
      if (route.unknown) sum.push({ t: ' Lý do chưa rõ — cần ' }, { t: 'phân loại trước khi giao xử lý', b: true }, { t: '.' })
      else sum.push({ t: ' Nếu lý do là "' + route.k + '", xử lý nguyên nhân: ' }, { t: route.owner, b: true }, { t: '.' })
      var rutAlert = a1.rut > paceR
      var timesR = paceR ? a1.rut / paceR : 0
      var clbN = Math.round(clbLost)
      var tree = [
        { id: 'r', col: 0, ev: true, label: '−' + n + ' học sinh rời đi', v: u.ten.split(' (')[0], sub: 'Lý do: ' + route.k, src: 'that', formula: 'Sự kiện đầu vào: ' + n + ' học sinh, ' + mo.t.toLowerCase() },
        { id: 'a1', col: 1, p: ['r'], label: 'Sĩ số', v: self.fmtInt(a0.t9) + ' → ' + self.fmtInt(a1.t9), sub: self.fmtPct(a0.pct, 1) + ' → ' + self.fmtPct(a1.pct, 1) + ' chỉ tiêu', src: 'that', mag: revNow + ltvFuture,
          alert: self.statusPct(a0.pct) !== 'bad' && self.statusPct(a1.pct) === 'bad' ? 'bad' : null, formula: a0.t9 + ' − ' + n + ' = ' + a1.t9 + '; ' + a1.t9 + ' ÷ ' + u.kh + ' = ' + self.fmtPct(a1.pct, 1) },
        { id: 'a2', col: 1, p: ['r'], label: 'Rút học lũy kế · KPI 3', v: self.fmtPct(a1.rut, 1), sub: 'nhịp cho phép ' + self.fmtPct(paceR, 1) + (rutAlert ? ' · gấp ' + self.fmtNum(timesR, 1) + ' lần' : ''), src: 'that',
          alert: rutAlert ? 'bad' : null, formula: '(' + a0.di + ' + ' + n + ') ÷ sĩ số T8 ' + u.t8 + ' = ' + self.fmtPct(a1.rut, 1) + '; nhịp cho phép = 10%/năm ÷ 10 tháng × ' + mo.since + ' tháng = ' + self.fmtPct(paceR, 1) },
        { id: 'a3', col: 2, p: ['a1', 'a2'], label: 'Giải trình trước Hội đồng', v: ex1 ? 'Cần giải trình' : 'Theo dõi', sub: ex1 && !ex0 ? 'mới chuyển trạng thái' : (ex1 ? 'đã trong diện từ trước' : ''), src: 'that',
          alert: ex1 && !ex0 ? 'bad' : null, formula: self.explainWhy(a1, fn.conv, paceR) },
        { id: 'b1', col: 2, p: ['a1'], label: 'Doanh thu năm nay', v: '−' + self.fmtTy(revNow), sub: self.rangeTy(-revNow, 0.85, 1.15), src: 'uoc', mag: revNow,
          formula: n + ' × học phí BQ ' + self.fmtNum(u.hp, 1) + ' tr × ' + Math.round(mo.r * 9) + '/9 tháng; LN góp ≈ −' + self.fmtTy(revNow * self.mInc) + ' (biên 85%); khoảng theo học phí ±15%' }
      ]
      if (clbN >= 1) tree.push({ id: 'b2', col: 2, p: ['a1'], label: 'Câu lạc bộ', v: '−' + clbN + ' học viên', sub: 'theo tỷ lệ tham gia của đơn vị', src: 'uoc', formula: n + ' × tỷ lệ tham gia CLB (' + cl.label + ')' })
      tree.push(
        { id: 'c1', col: 3, p: ['b1'], label: 'Doanh thu các năm sau', v: '≈ −' + self.fmtTy(ltvFuture), sub: self.rangeTy(-ltvFuture, 0.6, 1.3), src: 'uoc', mag: ltvFuture,
          formula: n + ' × [(' + la.yrs + ' − 1) × ' + self.fmtNum(u.hp, 1) + ' tr' + (la.p ? ' + ' + self.fmtPct(la.p, 0) + ' × ' + la.ny + ' năm × ' + self.fmtNum(la.nhp, 1) + ' tr' : '') + ']; khoảng theo tỷ lệ giữ chân và học tiếp' },
        { id: 'c2', col: 3, p: ['b1'], label: 'Lead để tuyển bù', v: '≈ ' + self.fmtInt(leadsNeed) + ' lead', sub: 'chuyển đổi ' + self.fmtPct(fn.conv, 1) + ' · ' + self.fmtPct(leadsNeed / leadsMonth, 0) + ' lead/tháng', src: 'that',
          alert: leadsNeed > leadsMonth ? 'bad' : null, formula: n + ' ÷ ' + self.fmtPct(fn.conv, 1) + ' = ' + self.fmtInt(leadsNeed) + ' lead' },
        { id: 'b3', col: 3, p: ['a3'], label: route.unknown ? 'Chưa rõ lý do' : 'Xử lý nguyên nhân', v: route.unknown ? 'Cần phân loại' : route.owner, sub: route.unknown ? 'Hiệu trưởng phân loại trước' : 'lý do: ' + route.k, src: 'that', formula: route.act }
      )
      var dgaps = ['Xe đưa rước, bán trú, đồng phục (cần thu phí theo mã học sinh)', 'Anh chị em và người giới thiệu (cần quan hệ gia đình theo mã học sinh)']
      if (clbN < 1) dgaps.push('Câu lạc bộ: tác động dưới 1 học viên, không hiển thị')
      var bars = [
        { k: 'Đạt chỉ tiêu sĩ số', b: a0.pct, a: a1.pct, t: 1, max: 1.05, better: 'up', st: self.statusPct(a1.pct) },
        { k: 'Rút học lũy kế so với nhịp', b: a0.rut, a: a1.rut, t: paceR, max: Math.max(paceR * 2, a1.rut * 1.15), better: 'down', st: rutAlert ? 'bad' : 'good' }
      ]
      var hero = [
        { k: 'Doanh thu năm nay', v: '−' + self.fmtTy(revNow), sub: self.rangeTy(-revNow, 0.85, 1.15) + ' · LN góp −' + self.fmtTy(revNow * self.mInc), tone: 'none', src: 'uoc' },
        { k: 'Doanh thu các năm sau', v: '≈ −' + self.fmtTy(ltvFuture), sub: self.rangeTy(-ltvFuture, 0.6, 1.3), tone: 'none', src: 'uoc' },
        { k: 'Rút học lũy kế · KPI 3', from: self.fmtPct(a0.rut, 1), v: self.fmtPct(a1.rut, 1), sub: 'nhịp cho phép ' + self.fmtPct(paceR, 1) + (rutAlert ? ' · gấp ' + self.fmtNum(timesR, 1) + ' lần' : ''), tone: rutAlert ? 'bad' : 'none', src: 'that' },
        { k: 'Lead để tuyển bù', v: '≈ ' + self.fmtInt(leadsNeed), sub: self.fmtPct(leadsNeed / leadsMonth, 0) + ' lượng lead một tháng', tone: leadsNeed > leadsMonth ? 'bad' : 'none', src: 'that' }
      ]
      return { u: u, n: n, mo: mo, route: route, who: who, tree: tree, dgaps: dgaps, bars: bars, hero: hero, strip: { now: -revNow, future: -ltvFuture },
        title: n + ' học sinh ' + u.ten + ' rời đi ' + mo.t.toLowerCase(),
        whyTitle: 'Vì sao rời đi?',
        rings: [{ t: 'Vòng 1 · Trực tiếp', items: ring1 }, { t: 'Vòng 2 · Tiền và vận hành', items: ring2 }, { t: 'Vòng 3 · Dài hạn', items: ring3 }],
        sum: sum }
    },

    icSiso: function () {
      var self = this
      var u = null
      self.units.forEach(function (x) { if (x.k === self.impact.unit) u = x })
      var n = Math.max(1, self.impact.addN)
      var mo = self.monthOptions[0]
      self.monthOptions.forEach(function (o) { if (o.m === self.impact.month) mo = o })
      var u1 = Object.assign({}, u, { t9: u.t9 + n })
      var a0 = self.agg([u])
      var a1 = self.agg([u1])
      var all0 = self.all
      var all1 = self.agg(self.units.map(function (x) { return x.k === u.k ? u1 : x }))
      var fn = null
      self.funnels.forEach(function (x) { if (x.k === u.don) fn = x })
      var explain = function (a) { return self.statusPct(a.pct) === 'bad' || self.statusRut(a) === 'bad' || self.statusConv(fn.conv) === 'bad' }
      var ex0 = explain(a0)
      var ex1 = explain(a1)
      var needFor = function (t) { return Math.max(0, Math.ceil(u.kh * t - u1.t9)) }
      var cap = u.lop * self.classMax[u.k]
      var room0 = Math.max(0, cap - u.t9)
      var inRoom = Math.min(n, room0)
      var rev = n * u.hp * mo.r
      var ln = inRoom * u.hp * mo.r * self.mInc + (n - inRoom) * u.hp * mo.r * 0.5
      var groupT9 = 0
      self.units.forEach(function (x) { if (x.clbKey === u.clbKey) groupT9 += x.t9 })
      var cl = self.clb[u.clbKey]
      var clbGain = n * cl.t9 / groupT9
      var la = self.lifeAssume[u.k]
      var future = n * (Math.max(0, la.yrs - 1) * u.hp + la.p * la.ny * la.nhp)
      var leadsNeed = fn.conv > 0 ? n / fn.conv : 0
      var leadsMonth = fn.leads / 2
      var activeTv = self.tvts.filter(function (t) { return t.t8 + t.t9 > 0 }).length

      var gaps = u.khoi.map(function (k) { return { k: k.k, g: k.kh - k.t9, kh: k.kh, t9: k.t9 } }).sort(function (a, b) { return b.g - a.g })
      var why = gaps.slice(0, 3).map(function (k) {
        return { k: 'Thiếu nhiều nhất: ' + k.k, v: (k.g > 0 ? '−' + k.g : '+' + (-k.g)) + ' HS', note: k.t9 + '/' + k.kh + ' (' + self.fmtPct(k.t9 / k.kh, 0) + ')', o: u.owner, bad: k.g > 0 }
      })
      var flow = u.t8 + u.den9 - u.di9
      why.push({ k: 'Dòng chảy T8 → T9', v: (flow - u.t9 === 0 ? 'Khớp' : 'Lệch ' + Math.abs(flow - u.t9) + ' HS'), note: u.t8 + ' + ' + u.den9 + ' đến − ' + u.di9 + ' đi = ' + flow + '; báo cáo ' + u.t9, o: 'Vận hành', bad: flow !== u.t9 })
      why.push({ k: 'Chuyển đổi tuyển sinh', v: self.fmtPct(fn.conv, 1), note: fn.nh + '/' + fn.leads + ' lead T8–T9 · đích 30%', o: 'TVTS', bad: fn.conv < 0.2 })
      why.push({ k: 'Rút hồ sơ lũy kế', v: u.di + ' HS · ' + self.fmtPct(a0.rut, 1), note: 'Nhịp đích ' + self.fmtPct(self.rutPace, 1), o: u.owner, bad: self.statusRut(a0) === 'bad' })

      var ring1 = [
        { k: 'Sĩ số ' + u.ten, from: self.fmtInt(a0.t9), to: self.fmtInt(a1.t9), src: 'that' },
        { k: 'Đạt chỉ tiêu', from: self.fmtPct(a0.pct, 1), to: self.fmtPct(a1.pct, 1), src: 'that', good: self.statusPct(a0.pct) !== self.statusPct(a1.pct) },
        { k: 'Còn thiếu so với chỉ tiêu', from: self.fmtInt(a0.gap) + ' HS', to: self.fmtInt(a1.gap) + ' HS', src: 'that' },
        { k: 'Còn cần thêm để đạt 90% · 95% · 100%', v: needFor(0.9) + ' · ' + needFor(0.95) + ' · ' + needFor(1) + ' HS', src: 'that' },
        { k: 'Sĩ số bình quân/lớp', from: self.fmtNum(a0.t9 / u.lop, 1), to: self.fmtNum(a1.t9 / u.lop, 1), src: 'that', note: u.lop + ' lớp' },
        { k: 'Toàn hệ thống: sĩ số', from: self.fmtInt(all0.t9) + ' · ' + self.fmtPct(all0.pct, 1), to: self.fmtInt(all1.t9) + ' · ' + self.fmtPct(all1.pct, 1), src: 'that' },
        { k: 'Trạng thái đơn vị trên bảng Hội đồng', from: ex0 ? 'Cần giải trình' : 'Theo dõi', to: ex1 ? 'Cần giải trình' : 'Theo dõi', src: 'that', good: ex0 && !ex1, note: self.explainWhy(a1, fn.conv) }
      ]
      var ring2 = [
        { k: 'Doanh thu học phí năm nay', v: '+' + self.fmtTy(rev), src: 'uoc', pos: true, note: 'Học phí BQ ' + self.fmtNum(u.hp, 1) + ' tr/năm (niêm yết 2026) × ' + Math.round(mo.r * 9) + '/9 tháng' },
        { k: 'Lợi nhuận góp', v: '+' + self.fmtTy(ln), src: 'uoc', pos: true, note: inRoom >= n ? 'Xếp vào lớp đang mở, biên 85%' : (n - inRoom) + ' HS vượt chỗ trống, phải mở lớp mới (biên 50%)' },
        { k: 'Chỗ trống trong lớp đang mở', from: self.fmtInt(room0), to: self.fmtInt(Math.max(0, room0 - n)), src: 'uoc', note: 'Theo sĩ số chuẩn ' + self.classMax[u.k] + '/lớp · chưa có công suất thiết kế' },
        { k: 'Câu lạc bộ ngoại khóa', v: '≈ +' + self.fmtInt(clbGain) + ' học viên', src: 'uoc', pos: true, note: 'Theo tỷ lệ tham gia CLB của đơn vị (' + cl.label + ')' },
        { k: 'Bán trú, xe đưa rước, đồng phục', v: 'Chưa tính được', src: 'chua', note: 'Cần nối thu phí dịch vụ theo mã học sinh' }
      ]
      var ring3 = [
        { k: 'Doanh thu các năm học sau', v: '≈ +' + self.fmtTy(future), src: 'uoc', pos: true, note: 'Còn ~' + self.fmtNum(la.yrs, 1) + ' năm ở cấp này' + (la.p ? '; ' + self.fmtPct(la.p, 0) + ' học tiếp lên ' + la.nl : '') },
        { k: 'Lead cần có để tuyển được', v: '≈ ' + self.fmtInt(leadsNeed) + ' lead', src: 'that', bad: leadsNeed > leadsMonth * 2, note: 'Chuyển đổi hiện tại ' + self.fmtPct(fn.conv, 1) + ' · bằng ' + self.fmtNum(leadsNeed / leadsMonth, 1) + ' tháng lead hiện có' },
        { k: 'Tải tư vấn viên', v: '+' + self.fmtInt(leadsNeed / activeTv) + ' lead/người', src: 'that', note: activeTv + ' tư vấn viên đang nhận lead' },
        { k: 'Chi phí tuyển sinh', v: 'Chưa tính được', src: 'chua', note: 'Chưa có chi phí marketing theo kênh (CAC)' }
      ]
      var who = [
        { o: u.owner, a: 'Kế hoạch tuyển bổ sung ưu tiên ' + gaps[0].k + ' (thiếu ' + gaps[0].g + ' HS)' },
        { o: 'Tuyển sinh – TVTS', a: 'Cần khoảng ' + self.fmtInt(leadsNeed) + ' lead; phân bổ lại cho ' + activeTv + ' tư vấn viên' },
        { o: 'Marketing', a: 'Tăng lead đúng khối thiếu, giảm lead "không liên lạc được"' },
        { o: 'Kế toán', a: 'Cập nhật dự báo doanh thu' }
      ]
      var sum = [
        { t: 'Tuyển thêm ' + n + ' học sinh cho ' + u.ten + ' = ' }, { t: '+' + self.fmtTy(rev), b: true }, { t: ' doanh thu năm nay, ' },
        { t: '+' + self.fmtTy(future), b: true }, { t: ' doanh thu các năm sau; đạt chỉ tiêu ' + self.fmtPct(a0.pct, 1) + ' → ' }, { t: self.fmtPct(a1.pct, 1), b: true },
        { t: '. Muốn vậy cần khoảng ' }, { t: self.fmtInt(leadsNeed) + ' lead', b: true }, { t: ' (≈ ' + self.fmtNum(leadsNeed / leadsMonth, 1) + ' tháng lead hiện có) với chuyển đổi ' + self.fmtPct(fn.conv, 1) + '.' }
      ]
      if (ex0 && !ex1) sum.push({ t: ' ' + u.ten + ' ' }, { t: 'ra khỏi danh sách "Cần giải trình"', b: true }, { t: '.' })
      var better = function (x, y) { var r = { bad: 0, warn: 1, good: 2 }; return r[y] > r[x] }
      var perTv = leadsNeed / activeTv
      var tree = [
        { id: 'r', col: 0, ev: true, label: '+' + n + ' học sinh tuyển thêm', v: u.ten.split(' (')[0], sub: mo.t, src: 'that', formula: 'Sự kiện đầu vào: tuyển thêm ' + n + ' học sinh, ' + mo.t.toLowerCase() },
        { id: 'a1', col: 1, p: ['r'], label: 'Sĩ số', v: self.fmtInt(a0.t9) + ' → ' + self.fmtInt(a1.t9), sub: self.fmtPct(a0.pct, 1) + ' → ' + self.fmtPct(a1.pct, 1) + ' chỉ tiêu', src: 'that', mag: rev + future,
          alert: better(self.statusPct(a0.pct), self.statusPct(a1.pct)) ? 'good' : null, formula: a0.t9 + ' + ' + n + ' = ' + a1.t9 + '; ' + a1.t9 + ' ÷ ' + u.kh + ' = ' + self.fmtPct(a1.pct, 1) },
        { id: 'a2', col: 1, p: ['r'], label: 'Lead cần có', v: '≈ ' + self.fmtInt(leadsNeed) + ' lead', sub: self.fmtNum(leadsNeed / leadsMonth, 1) + ' tháng lead hiện có', src: 'that',
          alert: leadsNeed > leadsMonth * 2 ? 'bad' : null, formula: n + ' ÷ chuyển đổi ' + self.fmtPct(fn.conv, 1) + ' = ' + self.fmtInt(leadsNeed) + ' lead' },
        { id: 'a3', col: 2, p: ['a1'], label: 'Giải trình trước Hội đồng', v: ex1 ? 'Cần giải trình' : 'Theo dõi', sub: ex0 && !ex1 ? 'ra khỏi diện giải trình' : (ex1 ? 'vẫn còn tiêu chí đỏ' : ''), src: 'that',
          alert: ex0 && !ex1 ? 'good' : null, formula: self.explainWhy(a1, fn.conv) },
        { id: 'b1', col: 2, p: ['a1'], label: 'Doanh thu năm nay', v: '+' + self.fmtTy(rev), sub: self.rangeTy(rev, 0.85, 1.15), src: 'uoc', mag: rev,
          formula: n + ' × ' + self.fmtNum(u.hp, 1) + ' tr × ' + Math.round(mo.r * 9) + '/9 tháng; LN góp ≈ +' + self.fmtTy(ln) + (inRoom >= n ? ' (xếp vào lớp đang mở)' : ' (' + (n - inRoom) + ' HS cần mở lớp mới)') },
        { id: 'b2', col: 2, p: ['a1'], label: 'Chỗ trống lớp đang mở', v: room0 + ' → ' + Math.max(0, room0 - n), sub: 'chuẩn ' + self.classMax[u.k] + ' HS/lớp', src: 'uoc',
          alert: room0 - n < 0 ? 'bad' : null, formula: u.lop + ' lớp × ' + self.classMax[u.k] + ' − ' + u.t9 + ' = ' + room0 + ' chỗ' },
        { id: 'b3', col: 2, p: ['a2'], label: 'Tải tư vấn viên', v: '+' + self.fmtInt(perTv) + ' lead/người', sub: activeTv + ' tư vấn viên đang nhận lead', src: 'that',
          alert: perTv > 60 ? 'bad' : null, formula: self.fmtInt(leadsNeed) + ' ÷ ' + activeTv + ' người' },
        { id: 'c1', col: 3, p: ['b1'], label: 'Doanh thu các năm sau', v: '≈ +' + self.fmtTy(future), sub: self.rangeTy(future, 0.6, 1.3), src: 'uoc', mag: future,
          formula: n + ' × [(' + la.yrs + ' − 1) × ' + self.fmtNum(u.hp, 1) + ' tr' + (la.p ? ' + ' + self.fmtPct(la.p, 0) + ' × ' + la.ny + ' năm × ' + self.fmtNum(la.nhp, 1) + ' tr' : '') + ']' }
      ]
      var dgaps = ['Chi phí tuyển sinh theo kênh (CAC)', 'Bán trú, xe đưa rước (cần thu phí theo mã học sinh)']
      if (Math.round(clbGain) >= 1) dgaps.unshift('Câu lạc bộ: ≈ +' + Math.round(clbGain) + ' học viên (xem bảng chi tiết)')
      var bars = [
        { k: 'Đạt chỉ tiêu sĩ số', b: a0.pct, a: a1.pct, t: 1, max: 1.05, better: 'up', st: self.statusPct(a1.pct) },
        { k: 'Toàn hệ thống', b: all0.pct, a: all1.pct, t: 1, max: 1.05, better: 'up', st: self.statusPct(all1.pct) }
      ]
      var hero = [
        { k: 'Doanh thu năm nay', v: '+' + self.fmtTy(rev), sub: self.rangeTy(rev, 0.85, 1.15) + ' · LN góp +' + self.fmtTy(ln), tone: 'none', src: 'uoc' },
        { k: 'Doanh thu các năm sau', v: '≈ +' + self.fmtTy(future), sub: self.rangeTy(future, 0.6, 1.3), tone: 'none', src: 'uoc' },
        { k: 'Đạt chỉ tiêu · KPI 1', from: self.fmtPct(a0.pct, 1), v: self.fmtPct(a1.pct, 1), sub: a1.gap > 0 ? 'còn thiếu ' + a1.gap + ' học sinh' : 'đạt chỉ tiêu', tone: better(self.statusPct(a0.pct), self.statusPct(a1.pct)) ? 'good' : 'none', src: 'that' },
        { k: 'Lead cần có', v: '≈ ' + self.fmtInt(leadsNeed), sub: self.fmtNum(leadsNeed / leadsMonth, 1) + ' tháng lead hiện có', tone: leadsNeed > leadsMonth * 2 ? 'bad' : 'none', src: 'that' }
      ]
      return { tree: tree, dgaps: dgaps, bars: bars, hero: hero, strip: { now: rev, future: future },
        title: 'Tuyển thêm ' + n + ' học sinh cho ' + u.ten + ' ' + mo.t.toLowerCase(), whyTitle: 'Vì sao sĩ số đang như vậy?', why: why,
        whyNote: 'Bấm sang "Học sinh rời đi" để xem chiều ngược lại.',
        rings: [{ t: 'Vòng 1 · Trực tiếp', items: ring1 }, { t: 'Vòng 2 · Tiền và vận hành', items: ring2 }, { t: 'Vòng 3 · Dài hạn và nguồn lực', items: ring3 }],
        who: who, sum: sum }
    },

    icConv: function () {
      var self = this
      var f = null
      self.funnels.forEach(function (x) { if (x.k === self.impact.convUnit) f = x })
      var d = self.impact.convDelta / 100
      var months = self.impact.convMonths
      var c0 = f.conv
      var c1 = Math.max(0, Math.min(1, c0 + d))
      var leadsMonth = f.leads / 2
      var extra = leadsMonth * months * (c1 - c0)
      var group = self.units.filter(function (u) { return u.don === f.k })
      var g0 = self.agg(group)
      var t9b = g0.t9 + extra
      var pctB = g0.kh ? t9b / g0.kh : 0
      var allB = self.all.kh ? (self.all.t9 + extra) / self.all.kh : 0
      var remainAvg = Math.max(0, 8 - months / 2) / 9
      var rev = extra * f.hp * remainAvg
      var futPer = 0
      var wsum = 0
      group.forEach(function (u) {
        var la = self.lifeAssume[u.k]
        futPer += u.t9 * (Math.max(0, la.yrs - 1) * u.hp + la.p * la.ny * la.nhp)
        wsum += u.t9
      })
      futPer = wsum ? futPer / wsum : 0
      var future = extra * futPer
      var nhMonth = f.nh / 2
      var leadsNow = c0 > 0 ? nhMonth / c0 : 0
      var leadsAfter = c1 > 0 ? nhMonth / c1 : 0
      var perYear = leadsMonth * 12 * (c1 - c0)
      var fails = f.k === 'PTLC' ? self.failPtlc : self.failReasons
      var ftotal = 0
      fails.forEach(function (r) { ftotal += r.v })
      var why = fails.slice(0, 4).map(function (r) {
        var rt = self.failRoutes[r.k] || { o: 'TVTS', a: '' }
        return { k: r.k, v: r.v + ' lead · ' + self.fmtPct(r.v / ftotal, 0), note: rt.a, o: rt.o, bad: r.v / ftotal > 0.5 }
      })
      var top = self.failRoutes[fails[0].k] || { o: 'TVTS', a: '' }
      var sign = extra >= 0 ? '+' : '−'
      var reached = c1 >= 0.3 && c0 < 0.3
      var ring1 = [
        { k: 'Tỷ lệ chuyển đổi ' + f.ten, from: self.fmtPct(c0, 1), to: self.fmtPct(c1, 1), src: 'that', good: reached, note: reached ? 'Đạt đích KPI 30%' : 'Đích KPI 30%' },
        { k: 'Học sinh nhập học thêm trong ' + months + ' tháng', v: sign + self.fmtInt(Math.abs(extra)) + ' HS', src: 'that', pos: extra > 0, bad: extra < 0, note: self.fmtNum(leadsMonth, 1) + ' lead/tháng (BQ T8–T9) × ' + months + ' tháng' },
        { k: 'Sĩ số ' + (f.k === 'PTLC' ? 'Liên cấp (TH+THCS+THPT)' : f.ten), from: self.fmtInt(g0.t9), to: self.fmtInt(t9b), src: 'that' },
        { k: 'Đạt chỉ tiêu', from: self.fmtPct(g0.pct, 1), to: self.fmtPct(pctB, 1), src: 'that' },
        { k: 'Toàn hệ thống: đạt chỉ tiêu', from: self.fmtPct(self.all.pct, 1), to: self.fmtPct(allB, 1), src: 'that' },
        { k: 'Khoảng cách đến đích 30%', from: self.fmtNum(Math.max(0, 30 - c0 * 100), 1) + ' điểm', to: self.fmtNum(Math.max(0, 30 - c1 * 100), 1) + ' điểm', src: 'that' }
      ]
      var ring2 = [
        { k: 'Doanh thu học phí năm nay', v: sign + self.fmtTy(Math.abs(rev)), src: 'uoc', pos: rev > 0, bad: rev < 0, note: 'Học phí BQ ' + self.fmtNum(f.hp, 1) + ' tr/năm (niêm yết 2026); nhập học rải đều trong ' + months + ' tháng' },
        { k: 'Lợi nhuận góp', v: sign + self.fmtTy(Math.abs(rev * self.mInc)), src: 'uoc', pos: rev > 0, bad: rev < 0, note: 'Xếp vào lớp đang mở, biên 85%' },
        { k: 'Lead cần mỗi tháng cho cùng số nhập học', from: self.fmtInt(leadsNow), to: self.fmtInt(leadsAfter), src: 'that', note: 'Giữ nguyên ' + self.fmtNum(nhMonth, 1) + ' HS/tháng' },
        { k: 'Chi phí marketing tiết kiệm', v: 'Chưa tính được', src: 'chua', note: 'Chưa có chi phí trên mỗi lead' }
      ]
      var ring3 = [
        { k: 'Doanh thu các năm học sau', v: sign + self.fmtTy(Math.abs(future)), src: 'uoc', pos: future > 0, bad: future < 0, note: 'Theo số năm còn học và tỷ lệ học tiếp lên cấp trên' },
        { k: 'Nếu duy trì cả năm (12 tháng)', v: sign + self.fmtInt(Math.abs(perYear)) + ' HS/năm', src: 'that', pos: perYear > 0, bad: perYear < 0, note: '≈ ' + sign + self.fmtTy(Math.abs(perYear * f.hp)) + ' doanh thu/năm' },
        { k: 'KPI 5 (chuyển đổi 30%)', from: self.statusConv(c0) === 'bad' ? 'Dưới 20%' : (self.statusConv(c0) === 'warn' ? '20–30%' : 'Đạt'), to: self.statusConv(c1) === 'bad' ? 'Dưới 20%' : (self.statusConv(c1) === 'warn' ? '20–30%' : 'Đạt'), src: 'that' }
      ]
      var who = [
        { o: top.o, a: top.a + ' (' + self.fmtPct(fails[0].v / ftotal, 0) + ' lead thất bại vì "' + fails[0].k + '")' },
        { o: 'Tuyển sinh – TVTS', a: 'Chuẩn hóa kịch bản tư vấn, theo dõi chuyển đổi theo từng người' },
        { o: 'Marketing', a: 'Ưu tiên kênh có chất lượng lead cao (giới thiệu, phụ huynh LHBS)' },
        { o: 'IT', a: 'CRM gắn mã lead → mã học sinh để đo chuyển đổi theo cohort và theo tư vấn viên' }
      ]
      var sum = [
        { t: (d >= 0 ? 'Tăng' : 'Giảm') + ' chuyển đổi ' + f.ten + ' ' + Math.abs(self.impact.convDelta) + ' điểm trong ' + months + ' tháng = ' },
        { t: sign + self.fmtNum(Math.abs(extra), 0) + ' học sinh', b: true }, { t: ', ' }, { t: sign + self.fmtTy(Math.abs(rev)), b: true }, { t: ' doanh thu năm nay, ' },
        { t: sign + self.fmtTy(Math.abs(future)), b: true }, { t: ' doanh thu các năm sau. Đòn bẩy lớn nhất: xử lý ' }, { t: '"' + fails[0].k + '"', b: true },
        { t: ' (' + self.fmtPct(fails[0].v / ftotal, 0) + ' lead thất bại).' }
      ]
      var good = extra >= 0
      var betterC = function (x, y) { var r = { bad: 0, warn: 1, good: 2 }; return r[y] > r[x] }
      var tree = [
        { id: 'r', col: 0, ev: true, label: (self.impact.convDelta >= 0 ? '+' : '') + self.impact.convDelta + ' điểm chuyển đổi', v: f.ten.split(' (')[0], sub: 'trong ' + months + ' tháng tới', src: 'that', formula: 'Sự kiện đầu vào: chuyển đổi thay đổi ' + self.impact.convDelta + ' điểm %, áp dụng ' + months + ' tháng' },
        { id: 'a1', col: 1, p: ['r'], label: 'Tỷ lệ chuyển đổi · KPI 5', v: self.fmtPct(c0, 1) + ' → ' + self.fmtPct(c1, 1), sub: reached ? 'đạt đích 30%' : 'còn ' + self.fmtNum(Math.max(0, 30 - c1 * 100), 1) + ' điểm tới đích 30%', src: 'that',
          alert: reached ? 'good' : null, formula: self.fmtPct(c0, 1) + ' + ' + self.impact.convDelta + ' điểm; ngưỡng: ≥30% đạt, <20% đỏ' },
        { id: 'a2', col: 2, p: ['a1'], label: 'Học sinh nhập học thêm', v: sign + self.fmtInt(Math.abs(extra)) + ' học sinh', sub: self.fmtInt(leadsMonth) + ' lead/tháng × ' + months + ' tháng', src: 'that', mag: Math.abs(rev) + Math.abs(future),
          formula: self.fmtNum(leadsMonth, 1) + ' × ' + months + ' × ' + self.impact.convDelta + '% = ' + self.fmtNum(extra, 1) },
        { id: 'a3', col: 2, p: ['a1'], label: 'Lead cần mỗi tháng', v: self.fmtInt(leadsNow) + ' → ' + self.fmtInt(leadsAfter), sub: 'giữ nguyên ' + self.fmtNum(nhMonth, 1) + ' học sinh/tháng', src: 'that', formula: self.fmtNum(nhMonth, 1) + ' ÷ ' + self.fmtPct(c1, 1) },
        { id: 'c2', col: 2, p: ['a1'], label: 'Nếu duy trì 12 tháng', v: sign + self.fmtInt(Math.abs(perYear)) + ' học sinh/năm', sub: '≈ ' + sign + self.fmtTy(Math.abs(perYear * f.hp)) + ' doanh thu/năm', src: 'uoc', formula: self.fmtNum(leadsMonth, 1) + ' × 12 × ' + self.impact.convDelta + '%' },
        { id: 'b1', col: 3, p: ['a2'], label: 'Sĩ số đơn vị', v: self.fmtInt(g0.t9) + ' → ' + self.fmtInt(t9b), sub: self.fmtPct(g0.pct, 1) + ' → ' + self.fmtPct(pctB, 1) + ' chỉ tiêu', src: 'that',
          alert: betterC(self.statusPct(g0.pct), self.statusPct(pctB)) ? 'good' : null, formula: g0.t9 + ' ' + sign + ' ' + self.fmtNum(Math.abs(extra), 1) },
        { id: 'b2', col: 3, p: ['a2'], label: 'Doanh thu năm nay', v: sign + self.fmtTy(Math.abs(rev)), sub: self.rangeTy(rev, 0.85, 1.15), src: 'uoc', mag: Math.abs(rev),
          formula: self.fmtNum(extra, 1) + ' × ' + self.fmtNum(f.hp, 1) + ' tr × ' + self.fmtNum(remainAvg * 9, 1) + '/9 tháng BQ; LN góp ≈ ' + sign + self.fmtTy(Math.abs(rev * self.mInc)) },
        { id: 'c1', col: 3, p: ['a2'], label: 'Doanh thu các năm sau', v: sign + self.fmtTy(Math.abs(future)), sub: self.rangeTy(future, 0.6, 1.3), src: 'uoc', mag: Math.abs(future),
          formula: self.fmtNum(extra, 1) + ' HS × giá trị BQ ' + self.fmtTy(futPer) + '/HS' }
      ]
      var dgaps = ['Chi phí marketing trên mỗi lead (để quy số lead tiết kiệm ra tiền)']
      var bars = [
        { k: 'Tỷ lệ chuyển đổi', b: c0, a: c1, t: 0.3, max: Math.max(0.35, c1 * 1.1), better: 'up', st: self.statusConv(c1) },
        { k: 'Đạt chỉ tiêu sĩ số', b: g0.pct, a: pctB, t: 1, max: 1.05, better: 'up', st: self.statusPct(pctB) }
      ]
      var hero = [
        { k: 'Học sinh nhập học thêm', v: sign + self.fmtInt(Math.abs(extra)), sub: 'trong ' + months + ' tháng · ' + sign + self.fmtInt(Math.abs(perYear)) + ' học sinh/năm nếu duy trì', tone: 'none', src: 'that' },
        { k: 'Doanh thu năm nay', v: sign + self.fmtTy(Math.abs(rev)), sub: self.rangeTy(rev, 0.85, 1.15), tone: 'none', src: 'uoc' },
        { k: 'Doanh thu các năm sau', v: sign + self.fmtTy(Math.abs(future)), sub: self.rangeTy(future, 0.6, 1.3), tone: 'none', src: 'uoc' },
        { k: 'Chuyển đổi · KPI 5', from: self.fmtPct(c0, 1), v: self.fmtPct(c1, 1), sub: reached ? 'đạt đích 30%' : 'còn ' + self.fmtNum(Math.max(0, 30 - c1 * 100), 1) + ' điểm tới 30%', tone: reached ? 'good' : 'none', src: 'that' }
      ]
      return { tree: tree, dgaps: dgaps, heads: ['Sự kiện', 'Vòng 1 · Trực tiếp', 'Vòng 2 · Tuyển sinh', 'Vòng 3 · Sĩ số & tiền'], bars: bars, hero: hero, strip: { now: rev, future: future },
        title: (d >= 0 ? 'Chuyển đổi ' : 'Chuyển đổi ') + f.ten + ' ' + (self.impact.convDelta >= 0 ? '+' : '') + self.impact.convDelta + ' điểm trong ' + months + ' tháng',
        whyTitle: 'Vì sao lead không thành học sinh?', why: why,
        whyNote: f.k === 'PTLC' ? 'Liên cấp: dữ liệu lý do thất bại còn ít (14 lead).' : 'Mầm non: số liệu gộp MN Biên Hòa và MN Long Khánh.',
        rings: [{ t: 'Vòng 1 · Trực tiếp', items: ring1 }, { t: 'Vòng 2 · Tiền và nguồn lực', items: ring2 }, { t: 'Vòng 3 · Dài hạn', items: ring3 }],
        who: who, sum: sum }
    },

    cur: function () {
      if (this.impact.type === 'siso') return this.icSiso
      if (this.impact.type === 'conv') return this.icConv
      return this.icRut
    },

    T: function () {
      var W = 940, NW = 190, NH = 58, VG = 10, TOP = 20
      var GAP = (W - 4 * NW) / 3
      var nodes = this.cur.tree
      var byCol = [[], [], [], []]
      nodes.forEach(function (n) { byCol[n.col].push(Object.assign({}, n)) })
      var maxRows = 1
      byCol.forEach(function (c) { if (c.length > maxRows) maxRows = c.length })
      var innerH = maxRows * NH + (maxRows - 1) * VG
      var pos = {}
      var placed = []
      var rowOf = {}
      byCol.forEach(function (c, ci) {
        if (ci > 0) {
          c.forEach(function (n, i) {
            var ps = (n.p || []).filter(function (pid) { return rowOf[pid] !== undefined })
            var sum = 0
            ps.forEach(function (pid) { sum += rowOf[pid] })
            n._bary = ps.length ? sum / ps.length : 99
            n._i = i
          })
          c.sort(function (x, y) { return (x._bary - y._bary) || (x._i - y._i) })
        }
        var h = c.length * NH + (c.length - 1) * VG
        var y0 = TOP + (innerH - h) / 2
        c.forEach(function (n, ri) {
          rowOf[n.id] = (y0 + ri * (NH + VG) + NH / 2 - TOP) / (NH + VG)
          var o = Object.assign({}, n, { x: ci * (NW + GAP), y: y0 + ri * (NH + VG) })
          pos[n.id] = o
          placed.push(o)
        })
      })
      var magMax = 0
      nodes.forEach(function (n) { if (n.mag && Math.abs(n.mag) > magMax) magMax = Math.abs(n.mag) })
      var edges = []
      placed.forEach(function (c) {
        (c.p || []).forEach(function (pid) {
          var pa = pos[pid]
          if (!pa || pa.col >= c.col) return
          var x1 = pa.x + NW, y1 = pa.y + NH / 2, x2 = c.x, y2 = c.y + NH / 2
          var dx = x2 - x1
          var w = c.mag && magMax ? 1.5 + 8 * Math.abs(c.mag) / magMax : 1.5
          edges.push({ id: pid + '-' + c.id, from: pid, to: c.id, w: w, state: c.state, src: c.src,
            d: 'M' + x1 + ' ' + y1 + ' C' + (x1 + dx / 2) + ' ' + y1 + ' ' + (x2 - dx / 2) + ' ' + y2 + ' ' + x2 + ' ' + y2 })
        })
      })
      var headTxt = this.cur.heads || ['Sự kiện', 'Vòng 1 · Trực tiếp', 'Vòng 2 · Tiền & vận hành', 'Vòng 3 · Dài hạn']
      var heads = headTxt.map(function (t, i) { return { t: t, x: i * (NW + GAP) } })
      return { W: W, H: TOP + innerH + 4, NW: NW, NH: NH, nodes: placed, edges: edges, heads: heads }
    },

    hlSet: function () {
      var id = this.impact.hover
      if (!id) return null
      var nodes = this.cur.tree
      var set = {}
      set[id] = true
      var up = function (nid) {
        nodes.forEach(function (n) { if (n.id === nid) (n.p || []).forEach(function (pid) { if (!set[pid]) { set[pid] = true; up(pid) } }) })
      }
      var down = function (nid) {
        nodes.forEach(function (n) { if ((n.p || []).indexOf(nid) >= 0 && !set[n.id]) { set[n.id] = true; down(n.id) } })
      }
      up(id)
      down(id)
      return set
    },

    hoverNode: function () {
      var id = this.impact.hover
      var hit = null
      this.cur.tree.forEach(function (n) { if (n.id === id) hit = n })
      return hit
    }
  },

  mounted: function () {
    var self = this
    self._escHandler = function (e) { if (e.key === 'Escape' && self.impact.open) self.impact.open = false }
    window.addEventListener('keydown', self._escHandler)
  },

  beforeUnmount: function () {
    if (this._escHandler) window.removeEventListener('keydown', this._escHandler)
  },

  methods: {
    agg: function (rows) {
      var m = { kh: 0, t5: 0, t8: 0, t9: 0, lop: 0, di: 0, di9: 0, den: 0, den9: 0, vGap: 0, hpSum: 0 }
      var self = this
      var fields = ['kh', 't5', 't8', 't9', 'lop', 'di', 'di9', 'den', 'den9']
      rows.forEach(function (r) {
        fields.forEach(function (f) { m[f] += r[f] })
        m.vGap += Math.max(0, r.kh - r.t9) * r.hp * self.remain
        m.hpSum += r.t9 * r.hp
      })
      m.gap = Math.max(0, m.kh - m.t9)
      m.pct = m.kh ? m.t9 / m.kh : 0
      m.rut = m.t8 ? m.di / m.t8 : 0
      m.hpAvg = m.t9 ? m.hpSum / m.t9 : 0
      return m
    },

    nodeClass: function (nd) {
      var c = ['t-node', nd.alert ? 'ta-' + nd.alert : 'ta-none', nd.src === 'uoc' ? 'is-est' : 'is-real']
      if (nd.ev) c.push('is-event')
      if (this.hlSet && !this.hlSet[nd.id]) c.push('is-dim')
      if (this.impact.hover === nd.id) c.push('is-hover')
      return c
    },

    edgeClass: function (e) {
      var c = ['t-edge']
      if (this.hlSet) c.push(this.hlSet[e.from] && this.hlSet[e.to] ? 'is-hl' : 'is-dim')
      return c
    },

    stripPct: function (v) {
      var tot = Math.abs(this.cur.strip.now) + Math.abs(this.cur.strip.future)
      return tot ? Math.abs(v) / tot * 100 : 0
    },

    signTy: function (v) {
      return (v < 0 ? '−' : '+') + this.fmtTy(Math.abs(v))
    },

    explainWhy: function (a, conv, pace) {
      var out = []
      if (this.statusPct(a.pct) === 'bad') out.push('sĩ số ' + this.fmtPct(a.pct, 1) + ' < 90%')
      if (pace ? a.rut > pace * 1.3 : this.statusRut(a) === 'bad') out.push('rút ' + this.fmtPct(a.rut, 1) + ' vượt nhịp')
      if (this.statusConv(conv) === 'bad') out.push('chuyển đổi ' + this.fmtPct(conv, 1) + ' < 20%')
      return out.length ? 'Vì ' + out.join(', ') : 'Không còn tiêu chí đỏ'
    },

    flowOf: function (base, vin, vout, months) {
      var pace = this.rutTargetYear / 10 * months
      var rate = base > 0 ? vout / base : 0
      var repl = vout > 0 ? vin / vout : (vin > 0 ? 99 : 1)
      var hiOut = rate > pace
      var lowIn = vin < vout
      var v = hiOut ? (lowIn ? 'xau' : 'bu') : (lowIn ? 'thieu' : 'tot')
      return { base: base, vin: vin, vout: vout, net: vin - vout, rate: rate, pace: pace, repl: repl, annual: rate / months * 10, v: v }
    },

    simCalc: function (st) {
      var self = this
      var mo = self.monthOptions[0]
      self.monthOptions.forEach(function (o) { if (o.m === st.start) mo = o })
      var M = Math.round(mo.r * 9)
      var run = st.mode === 'run'
      var outflow = st.mode !== 'hold'
      var avgR = (M / 2) / 9
      var startR = M / 9
      var fx = {}
      var leadsBase = 0, leadsScen = 0, nBase = 0, nScen = 0
      ;['PTLC', 'MNBH', 'MNLK'].forEach(function (k) {
        var f = self.funnelRaw[k]
        var c9 = f.l9 ? f.n9 / f.l9 : 0
        var L = (st.lead[k] || 0) / 100
        var D = Math.max(-c9, (st.conv[k] || 0) / 100)
        fx[k] = { conv: M * f.l9 * D, lead: M * f.l9 * L * (c9 + D), D: D }
        leadsBase += f.l9
        leadsScen += f.l9 * (1 + L)
        nBase += f.n9
        nScen += f.l9 * (1 + L) * (c9 + D)
      })
      var gapSum = 0
      self.units.forEach(function (u) { if (u.don === 'PTLC') gapSum += Math.max(0, u.kh - u.t9) })
      var tot = { kh: 0, end: 0, endBase: 0, dRev: 0, dLn: 0, dLtv: 0, dLtvRev: 0, explain: 0, t8: 0, di: 0, rut: 0, contrib: { conv: 0, lead: 0, keep: 0, add: 0 }, ln: { conv: 0, lead: 0, keep: 0, add: 0 } }
      var units = self.units.map(function (u) {
        var share = u.don === 'PTLC' ? (gapSum ? Math.max(0, u.kh - u.t9) / gapSum : 1 / 3) : 1
        var fConv = fx[u.don].conv * share
        var fLead = fx[u.don].lead * share
        var rutBase = outflow ? u.di9 * M : 0
        var saved = rutBase * (st.keep[u.k] || 0) / 100
        var rutScen = rutBase - saved
        var add = st.add[u.k] || 0
        var endBase = u.t9 + (run ? u.den9 * M : 0) - rutBase
        var end = endBase + saved + fConv + fLead + add
        var la = self.lifeAssume[u.k]
        var fut = Math.max(0, la.yrs - 1) * u.hp + la.p * la.ny * la.nhp
        var rv = function (hs, r) { return hs * u.hp * r }
        var dRev = rv(saved + fConv + fLead, avgR) + rv(add, startR)
        var f = null
        self.funnels.forEach(function (x) { if (x.k === u.don) f = x })
        var conv = f.conv + fx[u.don].D
        var rutYear = (u.di + rutScen) / u.t8
        var pct = end / u.kh
        var reasons = []
        if (self.statusPct(pct) === 'bad') reasons.push('sĩ số <90%')
        if (rutYear > self.rutTargetYear) reasons.push('rút >10%')
        if (self.statusConv(conv) === 'bad') reasons.push('chuyển đổi <20%')
        tot.kh += u.kh; tot.end += end; tot.endBase += endBase; tot.dRev += dRev; tot.dLn += dRev * self.mInc; tot.dLtv += (end - endBase) * fut * self.mAvgLong; tot.dLtvRev += (end - endBase) * fut
        tot.t8 += u.t8; tot.di += u.di; tot.rut += rutScen
        if (reasons.length) tot.explain++
        tot.contrib.conv += fConv; tot.contrib.lead += fLead; tot.contrib.keep += saved; tot.contrib.add += add
        tot.ln.conv += rv(fConv, avgR) * self.mInc; tot.ln.lead += rv(fLead, avgR) * self.mInc; tot.ln.keep += rv(saved, avgR) * self.mInc; tot.ln.add += rv(add, startR) * self.mInc
        return { k: u.k, ten: u.ten, owner: u.owner, don: u.don, kh: u.kh, end: end, pct: pct, rutYear: rutYear, conv: conv,
          dHs: end - endBase, dRev: dRev, dLn: dRev * self.mInc, dLtv: (end - endBase) * fut * self.mAvgLong, explain: reasons.length > 0,
          why: reasons.length ? reasons.join(', ') : 'không còn tiêu chí đỏ', cap: u.lop * self.classMax[u.k] }
      })
      var cost = (st.cost.mkt || 0) + (st.cost.keep || 0) + (st.cost.add || 0)
      var gain = tot.dLn + tot.dLtv
      var net = gain - cost
      var payback = '—'
      if (cost > 0) payback = tot.dLn >= cost ? 'trong năm học này' : (gain >= cost ? 'trong vòng đời học sinh' : 'không hoàn vốn')
      return { M: M, units: units, kh: tot.kh, end: tot.end, endBase: tot.endBase, pct: tot.end / tot.kh, rutYear: (tot.di + tot.rut) / tot.t8,
        conv: leadsScen ? nScen / leadsScen : 0, convBase: leadsBase ? nBase / leadsBase : 0, leads: leadsScen,
        dRev: tot.dRev, dLn: tot.dLn, dLtv: tot.dLtv, dLtvRev: tot.dLtvRev, explain: tot.explain, contrib: tot.contrib, lnContrib: tot.ln,
        cost: cost, net: net, roi: cost ? gain / cost : 0, roiYear: cost ? tot.dLn / cost : 0, payback: payback, fx: fx,
        newHs: tot.contrib.conv + tot.contrib.lead + tot.contrib.add, keptHs: tot.contrib.keep }
    },

    applyPreset: function (k) {
      var st = this.sim
      var setAll = function (obj, v) { Object.keys(obj).forEach(function (x) { obj[x] = typeof v === 'object' ? (v[x] || 0) : v }) }
      if (k === 'hien') {
        setAll(st.lead, 0); setAll(st.conv, 0); setAll(st.keep, 0); setAll(st.add, 0); setAll(st.cost, 0)
      } else if (k === 'ke') {
        setAll(st.lead, 20); setAll(st.conv, { PTLC: 3, MNBH: 5, MNLK: 8 }); setAll(st.keep, 30)
        setAll(st.add, { MNBH: 0, MNLK: 10, TH: 0, THCS: 0, THPT: 10 }); setAll(st.cost, { mkt: 1700, keep: 300, add: 300 })
      } else if (k === 'tv') {
        setAll(st.lead, 40); setAll(st.conv, { PTLC: 6, MNBH: 10, MNLK: 12 }); setAll(st.keep, 50)
        setAll(st.add, { MNBH: 0, MNLK: 20, TH: 10, THCS: 10, THPT: 20 }); setAll(st.cost, { mkt: 3600, keep: 600, add: 900 })
      }
      this.simPreset = k
    },

    saveScenario: function () {
      var names = { hien: 'Dự báo nền', ke: 'Kế hoạch đề xuất', tv: 'Tham vọng', custom: 'Tùy chỉnh' }
      var id = Date.now()
      var item = { id: id, name: (names[this.simPreset] || 'Kịch bản') + ' ' + (this.saved.length + 1), out: this.simCalc(JSON.parse(JSON.stringify(this.sim))) }
      this.saved = this.saved.concat([item]).slice(-3)
    },

    clearScenarios: function () {
      this.saved = []
    },

    tone: function (v) {
      return v > 0.0001 ? 'tx-good' : (v < -0.0001 ? 'tx-bad' : '')
    },

    rutStatus: function (r) {
      return r <= 0.08 ? 'good' : (r <= this.rutTargetYear ? 'warn' : 'bad')
    },

    exportPack: function () {
      var self = this
      var d = new Date()
      var pad = function (x) { return (x < 10 ? '0' : '') + x }
      self.printedAt = 'In lúc ' + pad(d.getHours()) + ':' + pad(d.getMinutes()) + ' ' + pad(d.getDate()) + '/' + pad(d.getMonth() + 1) + '/' + d.getFullYear()
      self.impact.open = false
      self.printing = true
      var oldTitle = document.title
      var done = function () {
        self.printing = false
        document.title = oldTitle
        window.removeEventListener('afterprint', done)
      }
      window.addEventListener('afterprint', done)
      self.$nextTick(function () {
        document.title = 'LHBS_BaoCaoHoiDong_T9-2026'
        setTimeout(function () { window.print() }, 150)
      })
    },

    openImpact: function (k, type) {
      var u = (k && k !== 'ALL') ? k : 'MNLK'
      this.impact.unit = u
      this.impact.type = type || 'rut'
      this.impact.hover = ''
      this.impact.reason = 5
      var self = this
      self.units.forEach(function (x) { if (x.k === u) self.impact.convUnit = x.don })
      this.impact.open = true
    },

    openUnit: function (k) {
      this.unit = k
      this.page = 1
    },

    drill: function (r) {
      if (r.drill) this.unit = r.k
    },

    statusPct: function (p) {
      return p >= 0.95 ? 'good' : (p >= 0.9 ? 'warn' : 'bad')
    },

    statusRut: function (m) {
      var p = this.rutPace
      return m.rut <= p * 0.85 ? 'good' : (m.rut <= p * 1.3 ? 'warn' : 'bad')
    },

    statusConv: function (c) {
      return c >= 0.3 ? 'good' : (c >= 0.2 ? 'warn' : 'bad')
    },

    statusKey: function (s) {
      var map = { 'Đạt': 'good', 'Đạt một phần': 'part', 'Đang chuẩn bị': 'prep', 'Cần xác minh': 'warn', 'Chưa đạt': 'bad', 'Chưa đủ dữ liệu': 'none' }
      return map[s] || 'none'
    },

    unitLabel: function (u) {
      if (u === 'ALL') return 'Toàn hệ thống'
      var t = u
      this.unitOptions.forEach(function (o) { if (o.k === u) t = o.t })
      return t
    },

    niceStep: function (raw) {
      var p = Math.pow(10, Math.floor(Math.log10(Math.max(raw, 1))))
      var n = raw / p
      return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * p
    },

    feedRate: function (k) {
      var v = Number(this.feed[k])
      if (isNaN(v)) v = 0
      return Math.min(100, Math.max(0, v)) / 100
    },

    spark: function (vals, labels, texts, target) {
      var all = vals.slice()
      var hasT = target !== null && target !== undefined
      if (hasT) all.push(target)
      var lo = Math.min.apply(null, all)
      var hi = Math.max.apply(null, all)
      if (hi - lo < 1e-9) { hi = lo + 1; lo = lo - 1 }
      var pad = (hi - lo) * 0.15
      lo -= pad
      hi += pad
      var n = vals.length
      var X = function (i) { return n === 1 ? 60 : 12 + i * (96 / (n - 1)) }
      var Y = function (v) { return 4 + (1 - (v - lo) / (hi - lo)) * 30 }
      var dots = vals.map(function (v, i) { return { x: X(i), y: Y(v), l: labels[i], t: texts[i] } })
      return { line: dots.map(function (d) { return d.x.toFixed(1) + ',' + d.y.toFixed(1) }).join(' '), dots: dots, ty: hasT ? Y(target) : null }
    },

    cmpRow: function (tt, kh, cl, cls, py) {
      return [
        { k: 'Kế hoạch', v: kh, cls: '' },
        { k: 'Chênh lệch', v: cl, cls: cls },
        { k: 'NH trước', v: py, cls: 'is-py' }
      ]
    },

    pts: function (x) {
      return this.signed(x * 100, 1) + ' điểm'
    },

    tileSiso: function (m, go) {
      var self = this
      return { k: 'Sĩ số so với chỉ tiêu', v: self.fmtPct(m.pct, 1), st: self.statusPct(m.pct), go: go,
        d: 'Chưa có công suất thiết kế nên KPI 1 chưa đo được',
        sp: self.spark([m.t5, m.t8, m.t9], ['T5', 'T8', 'T9'], [self.fmtInt(m.t5), self.fmtInt(m.t8), self.fmtInt(m.t9)], m.kh),
        cmp: self.cmpRow(self.fmtInt(m.t9), self.fmtInt(m.kh), self.signed(m.t9 - m.kh, 0), m.t9 >= m.kh ? 'is-good' : 'is-bad', self.fmtInt(m.t5)) }
    },

    tileRev: function (rows, m, go) {
      var self = this
      var tt = 0
      var kh = 0
      var g8 = 0
      rows.forEach(function (r) {
        tt += r.t9 * r.hp * self.remain
        kh += r.kh * r.hp * self.remain
        g8 += Math.max(0, r.kh - r.t8) * r.hp * self.remain
      })
      return { k: 'Doanh thu học phí còn lại', v: self.fmtTy(tt), st: tt >= kh ? 'good' : (tt >= kh * 0.95 ? 'warn' : 'bad'), go: go,
        d: 'Ước tính: sĩ số × học phí niêm yết × 8 tháng học còn lại',
        sp: self.spark([g8, m.vGap], ['T8', 'T9'], [self.fmtTy(g8), self.fmtTy(m.vGap)], 0),
        cmp: self.cmpRow(self.fmtTy(tt), self.fmtTy(kh), self.signTy(tt - kh), tt >= kh ? 'is-good' : 'is-bad', '—') }
    },

    tileRut: function (m, sys, go) {
      var self = this
      var r8 = m.t8 ? (m.di - m.di9) / m.t8 : 0
      return { k: 'Rút học lũy kế', v: self.fmtPct(m.rut, 1), st: self.statusRut(m), go: go,
        d: self.fmtInt(m.di) + ' HS sau 2 tháng · ngưỡng năm dưới 10% (KPI 3)',
        sp: self.spark([r8, m.rut], ['T8', 'T9'], [self.fmtPct(r8, 1), self.fmtPct(m.rut, 1)], self.rutPace),
        cmp: self.cmpRow(self.fmtPct(m.rut, 1), '≤ ' + self.fmtPct(self.rutPace, 1), self.pts(m.rut - self.rutPace), m.rut <= self.rutPace ? 'is-good' : 'is-bad', sys ? self.fmtPct(self.prevYear.rut, 0) : '—') }
    },

    tileNet: function (m) {
      var self = this
      var n9 = m.den - m.di
      var n8 = (m.den - m.den9) - (m.di - m.di9)
      return { k: 'Vào – ra ròng lũy kế (HS)', v: self.signed(n9, 0), st: n9 >= 0 ? 'good' : 'warn',
        d: 'Chuyển đến ' + m.den + ' · rút ' + m.di + ' kể từ T8',
        sp: self.spark([n8, n9], ['T8', 'T9'], [self.signed(n8, 0), self.signed(n9, 0)], 0),
        cmp: self.cmpRow(self.signed(n9, 0), '≥ 0', self.signed(n9, 0), n9 >= 0 ? 'is-good' : 'is-bad', '—') }
    },

    tileConv: function (go) {
      var self = this
      var f = self.funnelAll
      var fm = self.funnelMonth
      return { k: 'Chuyển đổi tuyển sinh', v: self.fmtPct(f.conv, 1), st: self.statusConv(f.conv), go: go,
        d: self.fmtInt(f.nh) + ' / ' + self.fmtInt(f.leads) + ' lead T8–T9 (KPI 5)',
        sp: self.spark([fm.c8, fm.c9], ['T8', 'T9'], [self.fmtPct(fm.c8, 1), self.fmtPct(fm.c9, 1)], 0.3),
        cmp: self.cmpRow(self.fmtPct(f.conv, 1), '30%', self.pts(f.conv - 0.3), f.conv >= 0.3 ? 'is-good' : 'is-bad', self.fmtPct(self.prevYear.conv, 1)) }
    },

    bySite: function (d) {
      return (d.split || '').toLowerCase().indexOf('cơ sở') >= 0
    },

    togglePresent: function () {
      this.present = !this.present
      if (this.present && this.presentPages.indexOf(this.page) < 0) this.page = 0
      if (typeof window !== 'undefined') window.scrollTo(0, 0)
    },

    pageOf: function (n) {
      return this.pages.filter(function (p) { return p.n === n })[0] || { t: '', s: '' }
    },

    rfShort: function (c) {
      var k = this.strategicKpis.filter(function (x) { return x.code === c })[0]
      return k ? k.short : c
    },

    rfGoalStat: function (g) {
      var self = this
      var r = { n: 0, has: 0, base: 0 }
      var sum = 0
      g.out.forEach(function (o) {
        self.rfOfOut(o.c).forEach(function (k) {
          r.n++
          var st = self.rfStatus(k.c)
          if (st === 'Đạt' || st === 'Đạt một phần') r.has++
          sum += self.rfBase(k.c)
        })
      })
      r.base = r.n ? Math.round(sum / r.n) : 0
      return r
    },

    rfStatus: function (c) {
      var k = this.strategicKpis.filter(function (x) { return x.code === c })[0]
      return k ? k.status : 'Chưa đủ dữ liệu'
    },

    rfBase: function (c) {
      var arr = this.rfBaseline[c] || []
      if (!arr.length) return 0
      var s = 0
      arr.forEach(function (b) { s += b.p })
      return Math.round(s / arr.length)
    },

    rfNext: function (k) {
      if (!k || !k.cut || !k.cut.length) return { d: 'Theo sự kiện', days: null, t: 0 }
      var now = new Date()
      now.setHours(0, 0, 0, 0)
      var best = null
      k.cut.forEach(function (x) {
        var p = x.split('/')
        var d = new Date(now.getFullYear(), Number(p[1]) - 1, Number(p[0]))
        if (d < now) d = new Date(now.getFullYear() + 1, Number(p[1]) - 1, Number(p[0]))
        if (!best || d < best) best = d
      })
      return { d: best.getDate() + '/' + (best.getMonth() + 1) + '/' + best.getFullYear(), days: Math.round((best - now) / 86400000), t: best.getTime() }
    },

    rfOfOut: function (oc) {
      return this.rfDict.filter(function (k) { return k.out === oc })
    },

    rfOps: function (c) {
      return this.kpiDict.filter(function (d) { return d.rfk === c })
    },

    groupsOf: function (row) {
      return this.pageGroups.filter(function (g) { return g.row === row })
    },

    selectRf: function (code) {
      this.dict.selD = code
      this.$nextTick(function () {
        if (typeof window === 'undefined' || window.innerWidth > 900) return
        var el = document.querySelector('.uc-kpi-rf__rfd')
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
    },

    openRf: function (code) {
      this.dict.tier = 'D'
      this.dict.q = ''
      this.dict.selD = code
      this.page = 9
      if (typeof window !== 'undefined') window.scrollTo(0, 0)
    },

    openOps: function (code) {
      this.dict.tier = 'A'
      this.dict.grp = 'ALL'
      this.dict.q = ''
      this.selectDict(code)
    },

    pagesOf: function (g) {
      return this.pages.filter(function (p) { return p.grp === g })
    },

    selectDict: function (code) {
      this.dict.sel = code
      this.$nextTick(function () {
        if (typeof window === 'undefined' || window.innerWidth > 900) return
        var el = document.querySelector('.uc-kpi-rf__dictd')
        if (el) el.scrollIntoView({ behavior: 'smooth', block: 'start' })
      })
    },

    openDict: function (code) {
      this.dict.grp = 'ALL'
      this.dict.q = ''
      this.dict.sel = code
      this.page = 9
      if (typeof window !== 'undefined') window.scrollTo(0, 0)
    },

    exportDict: function () {
      var self = this
      var cols = [['c', 'Mã'], ['g', 'Nhóm'], ['n', 'Tên chỉ số'], ['u', 'Đơn vị tính'], ['f', 'Tần suất'], ['cut', 'Ngày chốt'], ['num', 'Tử số'], ['den', 'Mẫu số'], ['rule', 'Quy tắc, loại trừ'], ['split', 'Phân tổ'], ['tgt', 'Mục tiêu'], ['rf', 'Tham chiếu Results Framework'], ['src', 'Hệ thống nguồn'], ['now', 'Cách thu hiện tại'], ['goal', 'Cách thu mục tiêu'], ['own', 'Chủ sở hữu'], ['chk', 'Kiểm tra'], ['apr', 'Phê duyệt'], ['st', 'Trạng thái'], ['note', 'Ghi chú'], ['gy', 'Góp ý']]
      var esc = function (v) { var t = v === undefined || v === null ? '' : String(v); return '"' + t.replace(/"/g, '""') + '"' }
      var lines = [cols.map(function (c) { return esc(c[1]) }).join(',')]
      self.kpiDict.forEach(function (d) {
        lines.push(cols.map(function (c) {
          var v = d[c[0]]
          if (c[0] === 'now' || c[0] === 'goal') v = self.modeText[v]
          if (c[0] === 'st') v = self.dictStatusText[v]
          if (c[0] === 'n' && d.add) v = v + ' (IT đề xuất)'
          return esc(v)
        }).join(','))
      })
      var blob = new Blob(['﻿' + lines.join('\r\n')], { type: 'text/csv;charset=utf-8' })
      var a = document.createElement('a')
      a.href = URL.createObjectURL(blob)
      a.download = 'tu-dien-kpi-lhbs-ban-nhap.csv'
      document.body.appendChild(a)
      a.click()
      setTimeout(function () { URL.revokeObjectURL(a.href); a.remove() }, 500)
    },

    bmQuad: function (p) {
      var M = this.bmMed
      if (!p) return { t: '', msg: '' }
      if (p.self && Math.abs(p.q - M.q) < 5) return { t: 'Chưa đủ căn cứ', msg: (p.fee >= M.fee ? 'Học phí trên' : 'Học phí dưới') + ' trung vị nhóm, nhưng trục đầu ra mới là giả định và đang ngang trung vị. Cần điểm thi vào 10, tốt nghiệp, trúng tuyển đại học của các trường (Sở GD&ĐT công bố) mới kết luận được vị trí.' }
      var hiF = p.fee >= M.fee, hiQ = p.q >= M.q
      if (hiF && hiQ) return { t: 'Cao cấp', msg: 'Học phí và đầu ra đều trên trung vị. Mức giá chỉ giữ được khi đầu ra được chứng minh bằng số thật (điểm thi, IELTS, đại học), không phải bằng giả định.' }
      if (!hiF && hiQ) return { t: 'Đáng tiền', msg: 'Đầu ra trên trung vị nhưng học phí dưới trung vị: có dư địa điều chỉnh giá, hoặc truyền thông mạnh hơn thông điệp "đáng tiền".' }
      if (hiF && !hiQ) return { t: 'Giá cao, đầu ra chưa tương xứng', msg: 'Học phí trên trung vị nhưng đầu ra dưới trung vị: rủi ro mất học sinh khi phụ huynh so sánh. Ưu tiên công bố kết quả đầu ra hoặc xem lại chính sách giá.' }
      return { t: 'Cạnh tranh bằng giá', msg: 'Học phí và đầu ra đều dưới trung vị: đang cạnh tranh bằng giá, dễ bị kéo vào cuộc đua giảm phí.' }
    },

    sankey: function (nodesIn, linksIn, heads, W, H, padL, padR) {
      var NW = 12, GAP = 10, TOP = 24, BOT = 4, PH = 14
      var copy = function (o) { var r = {}; Object.keys(o).forEach(function (k) { r[k] = o[k] }); return r }
      var nodes = nodesIn.map(function (n) { var o = copy(n); o.inV = 0; o.outV = 0; return o })
      var byId = {}
      nodes.forEach(function (n) { byId[n.id] = n })
      var links = linksIn.filter(function (l) { return l.v > 0 }).map(copy)
      links.forEach(function (l) { byId[l.s].outV += l.v; byId[l.t].inV += l.v })
      var maxCol = 0, cols = {}
      nodes.forEach(function (n) {
        n.val = Math.max(n.inV, n.outV)
        if (n.col > maxCol) maxCol = n.col
        if (!cols[n.col]) cols[n.col] = []
        cols[n.col].push(n)
      })
      var avail = H - TOP - BOT
      var k = 1e9
      Object.keys(cols).forEach(function (c) {
        var arr = cols[c], sum = 0, fixed = GAP * (arr.length - 1)
        arr.forEach(function (n) { if (n.ph) fixed += PH; else sum += n.val })
        if (sum > 0) k = Math.min(k, (avail - fixed) / sum)
      })
      var x0 = padL, x1 = W - padR - NW
      var colX = function (c) { return maxCol ? x0 + (x1 - x0) * c / maxCol : x0 }
      Object.keys(cols).forEach(function (c) {
        var arr = cols[c], tot = GAP * (arr.length - 1)
        arr.forEach(function (n) { n.h = n.ph ? PH : Math.max(n.val * k, 2); tot += n.h })
        var y = TOP + Math.max(0, (avail - tot) / 2)
        var last = -999
        var isL = Number(c) === 0
        arr.forEach(function (n) {
          n.x = colX(n.col)
          n.y = y
          n.so = 0
          n.to = 0
          y += n.h + GAP
          n.la = isL ? 'end' : 'start'
          n.lx = isL ? n.x - 6 : n.x + NW + 6
          var ly = n.y + n.h / 2 + 4
          if (ly < last + 13) ly = last + 13
          n.ly = ly
          last = ly
        })
      })
      var order = {}
      nodes.forEach(function (n, i) { order[n.id] = i })
      links.slice().sort(function (a, b) { return order[a.t] - order[b.t] }).forEach(function (l) {
        var s = byId[l.s]
        l.w = l.v * k
        l.y0 = s.y + s.so
        s.so += l.w
      })
      links.slice().sort(function (a, b) { return order[a.s] - order[b.s] }).forEach(function (l) {
        var t = byId[l.t]
        l.y1 = t.y + t.to
        t.to += l.w
      })
      var r = function (v) { return Math.round(v * 10) / 10 }
      links.forEach(function (l) {
        var xa = byId[l.s].x + NW, xb = byId[l.t].x, xm = (xa + xb) / 2
        l.d = 'M' + r(xa) + ',' + r(l.y0) + 'C' + r(xm) + ',' + r(l.y0) + ' ' + r(xm) + ',' + r(l.y1) + ' ' + r(xb) + ',' + r(l.y1) +
          'L' + r(xb) + ',' + r(l.y1 + l.w) + 'C' + r(xm) + ',' + r(l.y1 + l.w) + ' ' + r(xm) + ',' + r(l.y0 + l.w) + ' ' + r(xa) + ',' + r(l.y0 + l.w) + 'Z'
      })
      var hx = []
      for (var c = 0; c <= maxCol; c++) {
        var x = colX(c)
        hx.push({ t: heads[c] || '', x: c === 0 ? x + NW : (c === maxCol ? x : x + NW / 2), a: c === 0 ? 'end' : (c === maxCol ? 'start' : 'middle') })
      }
      return { W: W, H: H, nw: NW, nodes: nodes, links: links, heads: hx }
    },

    mapFocus: function (flow, id) {
      this.map.flow = flow
      this.map.hover = id || ''
    },

    mapSame: function (id) {
      var h = this.mapActive
      return h && h.charAt(0) === id.charAt(0)
    },

    mapNodeClass: function (n) {
      var c = ['s-node', 'sn-' + n.tone]
      if (n.ph) c.push('is-ph')
      if (this.mapSame(n.id)) c.push(this.mapHl[n.id] ? 'is-hl' : 'is-dim')
      return c
    },

    mapLinkClass: function (l) {
      var c = ['s-link', 'sl-' + l.tone]
      if (l.est) c.push('is-est')
      if (this.mapSame(l.s)) c.push(this.mapHl[l.s] && this.mapHl[l.t] ? 'is-hl' : 'is-dim')
      return c
    },

    mapNote: function (S) {
      var h = this.mapActive
      if (!h) return ''
      var n = S.nodes.filter(function (x) { return x.id === h })[0]
      return n ? n.note : ''
    },

    fmtInt: function (n) {
      return Math.round(n || 0).toLocaleString('vi-VN')
    },

    fmtNum: function (n, d) {
      return (n || 0).toLocaleString('vi-VN', { minimumFractionDigits: d, maximumFractionDigits: d })
    },

    fmtPct: function (x, d) {
      return this.fmtNum((x || 0) * 100, d) + '%'
    },

    fmtTyNum: function (trieu) {
      var v = (trieu || 0) / 1000
      if (Math.abs(v) < 0.005) return '0'
      return this.fmtNum(v, Math.abs(v) < 1 ? 2 : 1)
    },

    fmtTy: function (trieu) {
      return this.fmtTyNum(trieu) + ' tỷ'
    },

    rangeTy: function (v, lo, hi) {
      var sg = v < 0 ? '−' : '+'
      var a = Math.abs(v) * lo, b = Math.abs(v) * hi
      return 'khoảng ' + sg + this.fmtTyNum(a) + ' đến ' + sg + this.fmtTy(b)
    },

    signed: function (v, d) {
      return (v > 0 ? '+' : (v < 0 ? '−' : '±')) + this.fmtNum(Math.abs(v), d)
    }
  }
	}
</script>

<style scoped>
.uc-kpi-rf { --bg: #f3f2f1; --card: #ffffff; --line: #e1dfdd; --ink: #252423; --ink2: #605e5c; --ink3: #8a8886;
  --accent: #3A6EA5; --accent2: #1B365D; --good: #1a9e4b; --warn: #d9822b; --bad: #d13438;
  --good-t: #e7f4ec; --warn-t: #fdf1e3; --bad-t: #fbe9ea;
  background: var(--bg); color: var(--ink); min-height: 100vh; padding: 0 0 56px 0;
  font-family: 'Segoe UI', -apple-system, BlinkMacSystemFont, 'Helvetica Neue', Arial, sans-serif; font-size: 13px; }
.uc-kpi-rf .tx-good { color: var(--good); }
.uc-kpi-rf .tx-bad { color: var(--bad); }
.uc-kpi-rf .tx-warn { color: var(--warn); }
.uc-kpi-rf .tx-muted { color: var(--ink3); }
.uc-kpi-rf .tx-strong { font-weight: 600; }
.uc-kpi-rf .ta-l { text-align: left !important; }

.uc-kpi-rf__top { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; flex-wrap: wrap; background: var(--card); border-bottom: 1px solid var(--line); padding: 12px 20px; }
.uc-kpi-rf__title { font-size: 18px; font-weight: 600; letter-spacing: -0.2px; }
.uc-kpi-rf__subtitle { color: var(--ink2); margin-top: 2px; }
.uc-kpi-rf__meta { color: var(--ink2); display: flex; align-items: center; gap: 8px; flex-wrap: wrap; font-size: 12px; }
.uc-kpi-rf__sep { color: var(--line); }
.uc-kpi-rf__pill2 { border: 1px solid #c8c6c4; color: var(--ink2); padding: 1px 8px; font-size: 11px; font-weight: 600; }
.uc-kpi-rf__pill2.is-warn { border-color: var(--warn); color: var(--warn); }

.uc-kpi-rf__slicers { display: flex; align-items: flex-end; gap: 24px; flex-wrap: wrap; padding: 10px 20px; background: var(--card); border-bottom: 1px solid var(--line); }
.uc-kpi-rf__slicer-label { font-size: 11px; color: var(--ink2); margin-bottom: 4px; }
.uc-kpi-rf__seg { display: inline-flex; border: 1px solid #c8c6c4; flex-wrap: wrap; }
.uc-kpi-rf__seg button { padding: 4px 12px; background: #fff; color: var(--ink); border-right: 1px solid #c8c6c4; font-size: 12px; cursor: pointer; }
.uc-kpi-rf__seg button:last-child { border-right: 0; }
.uc-kpi-rf__seg button:hover { background: #f3f2f1; }
.uc-kpi-rf__seg button.is-on { background: var(--accent2); color: #fff; }
.uc-kpi-rf__seg--sm button { padding: 2px 8px; font-size: 11px; }
.uc-kpi-rf__view { padding: 4px 0; font-weight: 600; color: var(--accent2); }

.uc-kpi-rf__page { padding: 10px 20px 0; }
.uc-kpi-rf__lead { background: var(--accent2); color: #fff; padding: 12px 16px; margin-bottom: 8px; }
.uc-kpi-rf__lead-k { font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; opacity: 0.8; }
.uc-kpi-rf__lead-t { font-size: 14px; line-height: 1.6; margin-top: 4px; }
.uc-kpi-rf__lead-t b { font-weight: 700; }

.uc-kpi-rf__stats { display: grid; grid-template-columns: repeat(6, minmax(0, 1fr)); gap: 8px; margin-bottom: 8px; }
.uc-kpi-rf__stat { background: var(--card); border: 1px solid var(--line); border-left: 3px solid #c8c6c4; padding: 10px 12px; min-width: 0; }
.uc-kpi-rf__stat.st-l-good { border-left-color: var(--good); }
.uc-kpi-rf__stat.st-l-warn { border-left-color: var(--warn); }
.uc-kpi-rf__stat.st-l-bad { border-left-color: var(--bad); }
.uc-kpi-rf__stat-k { font-size: 11.5px; color: var(--ink2); }
.uc-kpi-rf__stat-v { font-size: 22px; font-weight: 600; margin-top: 4px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__stat-v small { font-size: 12px; font-weight: 400; color: var(--ink2); }
.uc-kpi-rf__stat-d { font-size: 11px; color: var(--ink3); margin-top: 2px; line-height: 1.35; }

.uc-kpi-rf__grid { display: grid; grid-template-columns: repeat(12, minmax(0, 1fr)); gap: 8px; }
.uc-kpi-rf__span7 { grid-column: span 7; }
.uc-kpi-rf__span5 { grid-column: span 5; }
.uc-kpi-rf__span12 { grid-column: span 12; }
.uc-kpi-rf__visual { background: var(--card); border: 1px solid var(--line); padding: 10px 14px; min-width: 0; display: flex; flex-direction: column; }
.uc-kpi-rf__vhead { display: flex; justify-content: space-between; align-items: center; gap: 8px; margin-bottom: 8px; flex-wrap: wrap; }
.uc-kpi-rf__vtitle { font-size: 14px; font-weight: 600; }
.uc-kpi-rf__vnote { font-size: 11px; color: var(--ink3); text-align: right; }
.uc-kpi-rf__link { color: var(--accent); cursor: pointer; font-weight: 600; }
.uc-kpi-rf__src { font-size: 10.5px; color: var(--ink3); margin-top: auto; padding-top: 8px; line-height: 1.4; }
.uc-kpi-rf__callout { background: #faf9f8; border-left: 3px solid var(--accent2); padding: 8px 10px; margin-top: 8px; line-height: 1.5; }

.uc-kpi-rf__tablewrap { overflow-x: auto; }
.uc-kpi-rf__table { width: 100%; border-collapse: collapse; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__table th { font-size: 11px; font-weight: 600; color: var(--ink2); text-align: right; padding: 6px 8px; border-bottom: 1px solid #c8c6c4; white-space: nowrap; }
.uc-kpi-rf__table td { text-align: right; padding: 6px 8px; border-bottom: 1px solid #f3f2f1; white-space: nowrap; vertical-align: middle; }
.uc-kpi-rf__table td small { display: block; font-size: 10px; color: var(--ink3); font-weight: 400; }
.uc-kpi-rf__table tbody tr { cursor: pointer; }
.uc-kpi-rf__table--plain tbody tr { cursor: default; }
.uc-kpi-rf__table tbody tr:hover td { filter: brightness(0.97); }
.uc-kpi-rf__table tr.is-total td { font-weight: 600; border-top: 1px solid #c8c6c4; background: #faf9f8; }
.uc-kpi-rf__table td.cell-good { background: var(--good-t); }
.uc-kpi-rf__table td.cell-warn { background: var(--warn-t); }
.uc-kpi-rf__table td.cell-bad { background: var(--bad-t); color: #a4262c; font-weight: 600; }
.uc-kpi-rf__table--wrap td { white-space: normal; vertical-align: top; line-height: 1.4; }
.uc-kpi-rf__th-bar { min-width: 160px; }

.uc-kpi-rf__tag { display: inline-block; font-size: 10.5px; font-weight: 600; padding: 1px 6px; border: 1px solid; white-space: nowrap; }
.uc-kpi-rf__tag.is-good { color: var(--good); border-color: #9fd3b2; background: #f2faf5; }
.uc-kpi-rf__tag.is-part { color: #3A6EA5; border-color: #B7C6D6; background: #EEF2F6; }
.uc-kpi-rf__tag.is-prep { color: #5C6B7A; border-color: #C9CFD6; background: #EEF0F3; }
.uc-kpi-rf__tag.is-warn { color: var(--warn); border-color: #f0c493; background: #fdf6ee; }
.uc-kpi-rf__tag.is-bad { color: var(--bad); border-color: #ef9a9c; background: #fdf3f3; }
.uc-kpi-rf__tag.is-none { color: var(--ink2); border-color: #d2d0ce; background: #f6f5f4; }
.uc-kpi-rf__fmt { font-size: 11px; padding: 1px 6px; border: 1px solid #d2d0ce; color: var(--ink2); white-space: nowrap; }
.uc-kpi-rf__fmt.fmt-pdf { border-color: #ef9a9c; color: var(--bad); }
.uc-kpi-rf__fmt.fmt-ppt { border-color: #f0c493; color: var(--warn); }

.uc-kpi-rf__risks { display: flex; flex-direction: column; }
.uc-kpi-rf__risk { display: flex; gap: 10px; padding: 7px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__lvl { flex-shrink: 0; width: 38px; text-align: center; font-size: 10.5px; font-weight: 700; line-height: 18px; height: 18px; color: #fff; }
.uc-kpi-rf__lvl.lvl-cao { background: var(--bad); }
.uc-kpi-rf__lvl.lvl-tb { background: var(--warn); }
.uc-kpi-rf__lvl.lvl-thap { background: #a19f9d; }
.uc-kpi-rf__risk-main { min-width: 0; }
.uc-kpi-rf__risk-t { font-weight: 600; }
.uc-kpi-rf__risk-d { font-size: 12px; color: var(--ink2); line-height: 1.4; margin-top: 1px; }
.uc-kpi-rf__risk-o { font-size: 11px; color: var(--ink3); margin-top: 2px; }

.uc-kpi-rf__stack { display: flex; height: 22px; background: #f3f2f1; }
.uc-kpi-rf__stack span { display: flex; align-items: center; justify-content: center; color: #fff; font-size: 11px; font-weight: 700; }
.uc-kpi-rf .sb-good { background: var(--good); }
.uc-kpi-rf .sb-part { background: #3A6EA5; }
.uc-kpi-rf .sb-prep { background: #5C6B7A; }
.uc-kpi-rf .sb-warn { background: var(--warn); }
.uc-kpi-rf .sb-bad { background: var(--bad); }
.uc-kpi-rf .sb-none { background: #a19f9d; }
.uc-kpi-rf__legend { display: flex; flex-wrap: wrap; gap: 4px 14px; margin: 6px 0 8px; font-size: 11px; color: var(--ink2); }
.uc-kpi-rf__legend i { display: inline-block; width: 9px; height: 9px; margin-right: 4px; }
.uc-kpi-rf__kpimini { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 0 18px; }
.uc-kpi-rf__kpimini-row { display: flex; align-items: center; gap: 8px; padding: 5px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__code { font-size: 11px; font-weight: 600; color: var(--ink2); width: 42px; flex-shrink: 0; }
.uc-kpi-rf__kpimini-n { flex: 1; min-width: 0; overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }

.uc-kpi-rf__trust { display: grid; grid-template-columns: repeat(2, minmax(0, 1fr)); gap: 8px; }
.uc-kpi-rf__trust div { border: 1px solid var(--line); padding: 8px 10px; }
.uc-kpi-rf__trust b { display: block; font-size: 22px; font-weight: 600; }
.uc-kpi-rf__trust span { font-size: 11.5px; color: var(--ink2); line-height: 1.35; }

.uc-kpi-rf__decisions { display: grid; grid-template-columns: repeat(auto-fill, minmax(380px, 1fr)); gap: 8px 20px; }
.uc-kpi-rf__decision { display: flex; gap: 10px; align-items: flex-start; padding: 6px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__decision-b { flex: 1; min-width: 0; }
.uc-kpi-rf__decision-n { width: 22px; height: 22px; flex-shrink: 0; background: var(--accent2); color: #fff; font-weight: 700; font-size: 12px; display: flex; align-items: center; justify-content: center; }
.uc-kpi-rf__decision-t { font-weight: 600; }
.uc-kpi-rf__decision-e { font-size: 12px; color: var(--ink2); line-height: 1.4; margin-top: 2px; }

.uc-kpi-rf__svg { width: 100%; height: auto; display: block; }
.uc-kpi-rf__svg .g-grid { stroke: #edebe9; stroke-width: 1; }
.uc-kpi-rf__svg .g-axis { fill: #605e5c; font-size: 10.5px; }
.uc-kpi-rf__svg .g-val { fill: #252423; font-size: 11px; font-weight: 600; }
.uc-kpi-rf__svg .g-money { fill: #d13438; font-size: 11px; font-weight: 600; }
.uc-kpi-rf__svg .g-conn { stroke: #a19f9d; stroke-width: 1; stroke-dasharray: 2 2; }
.uc-kpi-rf__svg .g-total { fill: #1B365D; }
.uc-kpi-rf__svg .g-end { fill: #3A6EA5; }
.uc-kpi-rf__svg .g-up { fill: #1a9e4b; }
.uc-kpi-rf__svg .g-down { fill: #d13438; }

.uc-kpi-rf__hbars { display: flex; flex-direction: column; gap: 7px; }
.uc-kpi-rf__hbar { display: grid; grid-template-columns: 190px 1fr 40px; gap: 8px; align-items: center; }
.uc-kpi-rf__hbar-l { font-size: 12px; }
.uc-kpi-rf__hbar-t { height: 14px; background: #f3f2f1; }
.uc-kpi-rf__hbar-t span { display: block; height: 100%; background: #6B88A8; }
.uc-kpi-rf__hbar-t span.is-bad { background: var(--bad); }
.uc-kpi-rf__hbar-n { text-align: right; font-weight: 600; font-variant-numeric: tabular-nums; }

.uc-kpi-rf__bullet-track { position: relative; height: 14px; background: #edebe9; min-width: 140px; }
.uc-kpi-rf__bullet-track .is-fill { position: absolute; left: 0; top: 3px; bottom: 3px; }
.uc-kpi-rf__bullet-track i { position: absolute; top: -2px; bottom: -2px; width: 2px; background: #252423; }
.uc-kpi-rf .st-good { background: var(--good); }
.uc-kpi-rf .st-warn { background: var(--warn); }
.uc-kpi-rf .st-bad { background: var(--bad); }

.uc-kpi-rf__funits { display: flex; flex-direction: column; gap: 12px; }
.uc-kpi-rf__funit-h { display: flex; justify-content: space-between; font-size: 13px; margin-bottom: 4px; }
.uc-kpi-rf__funit-h span { font-weight: 700; }
.uc-kpi-rf__funit-row { display: grid; grid-template-columns: 70px 1fr 40px; gap: 8px; align-items: center; margin-bottom: 3px; }
.uc-kpi-rf__funit-row span { font-size: 11.5px; color: var(--ink2); }
.uc-kpi-rf__funit-row > div { position: relative; height: 14px; background: #f3f2f1; }
.uc-kpi-rf__funit-row i { display: block; height: 100%; }
.uc-kpi-rf__funit-row i.is-lead { background: #1B365D; }
.uc-kpi-rf__funit-row i.is-nh { background: #3A6EA5; }
.uc-kpi-rf__funit-row em { position: absolute; top: -3px; bottom: -3px; width: 0; border-left: 2px dashed #252423; }
.uc-kpi-rf__funit-row b { text-align: right; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__funit-d { font-size: 11px; color: var(--ink3); }

.uc-kpi-rf__dbar { position: relative; height: 18px; background: #f3f2f1; min-width: 110px; }
.uc-kpi-rf__dbar span { position: absolute; left: 0; top: 0; bottom: 0; background: #A9BACC; }
.uc-kpi-rf__dbar em { position: relative; font-style: normal; padding-left: 6px; line-height: 18px; font-weight: 600; }

.uc-kpi-rf__olist { margin: 0; padding-left: 20px; display: flex; flex-direction: column; gap: 4px; font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__olist b { color: var(--ink); font-weight: 600; }
.uc-kpi-rf__assume { display: grid; grid-template-columns: repeat(auto-fill, minmax(300px, 1fr)); gap: 0 24px; }
.uc-kpi-rf__assume div { display: flex; justify-content: space-between; gap: 8px; padding: 5px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__assume span { color: var(--ink2); }

.uc-kpi-rf__tabs { position: fixed; left: 0; right: 0; bottom: 0; display: flex; background: #fff; border-top: 1px solid var(--line); padding: 0 12px; z-index: 5; overflow-x: auto; }
.uc-kpi-rf__tabs button { padding: 10px 16px; font-size: 12.5px; color: var(--ink2); border-top: 3px solid transparent; background: transparent; cursor: pointer; white-space: nowrap; }
.uc-kpi-rf__tabs button.is-on { color: var(--ink); font-weight: 600; border-top-color: var(--accent2); }

@media (max-width: 1280px) {
  .uc-kpi-rf__stats { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
@media (max-width: 900px) {
  .uc-kpi-rf__span7, .uc-kpi-rf__span5 { grid-column: span 12; }
  .uc-kpi-rf__kpimini, .uc-kpi-rf__trust { grid-template-columns: 1fr; }
}
@media (max-width: 600px) {
  .uc-kpi-rf__stats { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .uc-kpi-rf__page, .uc-kpi-rf__slicers, .uc-kpi-rf__top { padding-left: 12px; padding-right: 12px; }
  .uc-kpi-rf__hbar { grid-template-columns: 130px 1fr 36px; }
  .uc-kpi-rf__decisions { grid-template-columns: 1fr; }
}
.uc-kpi-rf__simbtn { margin-left: auto; align-self: center; padding: 6px 12px; border: 1px solid var(--accent2); color: var(--accent2); background: #fff; font-size: 12px; font-weight: 600; cursor: pointer; }
.uc-kpi-rf__simbtn:hover { background: var(--accent2); color: #fff; }
.uc-kpi-rf .is-click { cursor: pointer; }
.uc-kpi-rf__stat.is-click:hover { box-shadow: 0 0 0 1px var(--accent2) inset; }
.uc-kpi-rf__hint { float: right; color: var(--accent); font-size: 10.5px; font-weight: 600; }
.uc-kpi-rf__table td.is-click small { color: var(--accent); }
.uc-kpi-rf__veil { position: fixed; inset: 0; background: rgba(37, 36, 35, 0.35); z-index: 20; }
.uc-kpi-rf__drawer { position: fixed; top: 0; right: 0; bottom: 0; width: 600px; max-width: 100vw; background: var(--bg); z-index: 21; display: flex; flex-direction: column; box-shadow: -8px 0 24px rgba(0, 0, 0, 0.18); }
.uc-kpi-rf__dr-head { display: flex; justify-content: space-between; align-items: flex-start; gap: 12px; padding: 14px 18px; background: var(--accent2); color: #fff; }
.uc-kpi-rf__dr-kicker { font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; opacity: 0.8; }
.uc-kpi-rf__dr-title { font-size: 16px; font-weight: 600; margin-top: 2px; }
.uc-kpi-rf__dr-x { background: transparent; color: #fff; font-size: 24px; line-height: 1; cursor: pointer; padding: 0 4px; }
.uc-kpi-rf__dr-body { flex: 1; overflow-y: auto; padding: 12px 18px 20px; }
.uc-kpi-rf__dr-inputs { background: var(--card); border: 1px solid var(--line); padding: 10px 12px; display: flex; flex-direction: column; gap: 10px; }
.uc-kpi-rf__dr-row2 { display: grid; grid-template-columns: 1fr 160px; gap: 16px; align-items: end; }
.uc-kpi-rf__range { width: 100%; accent-color: #1B365D; }
.uc-kpi-rf__select { width: 100%; border: 1px solid #c8c6c4; padding: 4px 6px; font-size: 12px; background: #fff; }
.uc-kpi-rf__dr-sec { background: var(--card); border: 1px solid var(--line); padding: 10px 12px; margin-top: 8px; }
.uc-kpi-rf__dr-h { font-size: 13px; font-weight: 600; margin-bottom: 8px; display: flex; align-items: center; gap: 8px; }
.uc-kpi-rf__dr-h span { width: 20px; height: 20px; background: var(--accent2); color: #fff; font-size: 11px; display: inline-flex; align-items: center; justify-content: center; }
.uc-kpi-rf__chips { display: flex; flex-wrap: wrap; gap: 6px; margin-bottom: 8px; }
.uc-kpi-rf__chips button { border: 1px solid #c8c6c4; background: #fff; padding: 3px 10px; font-size: 12px; cursor: pointer; }
.uc-kpi-rf__chips button.is-on { background: var(--accent2); border-color: var(--accent2); color: #fff; }
.uc-kpi-rf__route { display: grid; grid-template-columns: 1fr 1fr; gap: 6px 14px; }
.uc-kpi-rf__route div { display: flex; flex-direction: column; }
.uc-kpi-rf__route span { font-size: 11px; color: var(--ink3); }
.uc-kpi-rf__route b { font-weight: 600; font-size: 12.5px; line-height: 1.35; }
.uc-kpi-rf__dr-note { font-size: 11px; color: var(--ink3); margin-top: 8px; }
.uc-kpi-rf__imp { display: grid; grid-template-columns: 1fr auto 96px; gap: 10px; align-items: center; padding: 6px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__imp.is-flag { background: #fdf3f3; margin: 0 -12px; padding: 6px 12px; }
.uc-kpi-rf__imp-l { font-size: 12.5px; }
.uc-kpi-rf__imp-l small { display: block; font-size: 11px; color: var(--ink3); }
.uc-kpi-rf__imp.is-flag .uc-kpi-rf__imp-l small { color: var(--bad); font-weight: 600; }
.uc-kpi-rf__imp-v { text-align: right; font-variant-numeric: tabular-nums; white-space: nowrap; }
.uc-kpi-rf__imp-v s { color: var(--ink3); text-decoration: none; }
.uc-kpi-rf__src-tag { font-size: 10px; font-weight: 600; padding: 1px 5px; border: 1px solid; text-align: center; white-space: nowrap; }
.uc-kpi-rf__src-tag.src-that { color: var(--good); border-color: #9fd3b2; }
.uc-kpi-rf__src-tag.src-uoc { color: var(--warn); border-color: #f0c493; }
.uc-kpi-rf__src-tag.src-chua { color: var(--ink3); border-color: #d2d0ce; border-style: dashed; }
.uc-kpi-rf__dr-sum { background: #fff8e8; border: 1px solid #e5c27a; border-left: 4px solid var(--warn); padding: 10px 12px; margin-top: 8px; }
.uc-kpi-rf__dr-sum-k { font-size: 11px; text-transform: uppercase; letter-spacing: 0.4px; color: #8a5a00; font-weight: 600; }
.uc-kpi-rf__dr-sum-t { font-size: 13.5px; line-height: 1.55; margin-top: 4px; }
.uc-kpi-rf__who { display: grid; grid-template-columns: 190px 1fr; gap: 10px; padding: 5px 0; border-bottom: 1px solid #f3f2f1; font-size: 12.5px; }
.uc-kpi-rf__who span { color: var(--ink2); }
.uc-kpi-rf__dr-foot { font-size: 11px; color: var(--ink3); line-height: 1.5; margin-top: 10px; }
@media (max-width: 600px) {
  .uc-kpi-rf__dr-row2, .uc-kpi-rf__route { grid-template-columns: 1fr; }
  .uc-kpi-rf__imp { grid-template-columns: 1fr auto; }
  .uc-kpi-rf__imp .uc-kpi-rf__src-tag { grid-column: 1 / -1; justify-self: start; }
  .uc-kpi-rf__who { grid-template-columns: 1fr; gap: 2px; }
}
.uc-kpi-rf__dr-types { display: flex; background: #fff; border-bottom: 1px solid var(--line); padding: 0 18px; }
.uc-kpi-rf__dr-types button { padding: 9px 12px; font-size: 12.5px; color: var(--ink2); border-bottom: 3px solid transparent; background: transparent; cursor: pointer; }
.uc-kpi-rf__dr-types button.is-on { color: var(--ink); font-weight: 600; border-bottom-color: var(--accent2); }
.uc-kpi-rf__drv { display: grid; grid-template-columns: 1fr auto 150px; gap: 10px; align-items: center; padding: 6px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__drv-l { font-size: 12.5px; }
.uc-kpi-rf__drv-l small { display: block; font-size: 11px; color: var(--ink3); }
.uc-kpi-rf__drv-v { text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__drv-o { font-size: 11px; color: var(--ink2); text-align: right; }
.uc-kpi-rf__imp.is-good { background: #f2faf5; margin: 0 -12px; padding: 6px 12px; }
.uc-kpi-rf__imp.is-good .uc-kpi-rf__imp-l small { color: var(--good); font-weight: 600; }
@media (max-width: 600px) {
  .uc-kpi-rf__drv { grid-template-columns: 1fr auto; }
  .uc-kpi-rf__drv-o { grid-column: 1 / -1; text-align: left; }
}
.uc-kpi-rf__hint2 { color: var(--accent); font-size: 10.5px; font-weight: 600; margin-left: 6px; }
.uc-kpi-rf__funit.is-click:hover { background: #faf9f8; }
.uc-kpi-rf__drawer { width: 780px !important; }
.uc-kpi-rf__dr-h2 { display: flex; justify-content: space-between; align-items: baseline; gap: 10px; flex-wrap: wrap; font-size: 13px; font-weight: 600; margin-bottom: 8px; }
.uc-kpi-rf__dr-h2 i { font-weight: 400; font-style: italic; color: var(--ink3); margin-left: 6px; font-size: 12px; }
.uc-kpi-rf__legend2 { display: flex; gap: 12px; flex-wrap: wrap; font-size: 10.5px; font-weight: 400; color: var(--ink2); }
.uc-kpi-rf__legend2 em { display: inline-block; width: 18px; height: 10px; margin-right: 4px; vertical-align: -1px; background: #fff; }
.uc-kpi-rf__legend2 .lg-that { border: 1.5px solid #252423; }
.uc-kpi-rf__legend2 .lg-uoc { border: 1.5px dashed #252423; }
.uc-kpi-rf__legend2 .lg-chua { border: 1.5px dotted #a19f9d; background: #f6f5f4; }
.uc-kpi-rf__legend2 .lg-w { height: 0; border-top: 5px solid #8a8886; width: 22px; vertical-align: 2px; }
.uc-kpi-rf__tree { width: 100%; height: auto; display: block; font-family: inherit; }
.uc-kpi-rf__tree .t-head { font-size: 10.5px; fill: #8a8886; font-weight: 600; letter-spacing: 0.3px; text-transform: uppercase; }
.uc-kpi-rf__tree .t-edge { stroke: #a19f9d; opacity: 0.75; transition: opacity 0.15s; }
.uc-kpi-rf__tree .t-edge.te-bad { stroke: #d13438; }
.uc-kpi-rf__tree .t-edge.te-good { stroke: #1a9e4b; }
.uc-kpi-rf__tree .t-edge.te-warn { stroke: #d9822b; }
.uc-kpi-rf__tree .t-edge.te-none { stroke: #c8c6c4; }
.uc-kpi-rf__tree .t-edge.is-dash { stroke-dasharray: 5 4; }
.uc-kpi-rf__tree .t-edge.is-dim { opacity: 0.12; }
.uc-kpi-rf__tree .t-node { cursor: pointer; transition: opacity 0.15s; }
.uc-kpi-rf__tree .t-node.is-dim { opacity: 0.28; }
.uc-kpi-rf__tree .t-box { fill: #ffffff; stroke: #252423; stroke-width: 1; }
.uc-kpi-rf__tree .ts-uoc .t-box { stroke-dasharray: 4 3; }
.uc-kpi-rf__tree .ts-chua .t-box { fill: #f6f5f4; stroke: #a19f9d; stroke-dasharray: 2 2; }
.uc-kpi-rf__tree .t-node.is-hover .t-box { stroke: #1B365D; stroke-width: 2; }
.uc-kpi-rf__tree .t-bar { fill: #a19f9d; }
.uc-kpi-rf__tree .tn-bad .t-bar { fill: #d13438; }
.uc-kpi-rf__tree .tn-good .t-bar { fill: #1a9e4b; }
.uc-kpi-rf__tree .tn-warn .t-bar { fill: #d9822b; }
.uc-kpi-rf__tree .tn-none .t-bar { fill: #c8c6c4; }
.uc-kpi-rf__tree .t-l { font-size: 11px; font-weight: 600; fill: #252423; }
.uc-kpi-rf__tree .t-en { font-size: 9.5px; font-style: italic; fill: #8a8886; }
.uc-kpi-rf__tree .t-v { font-size: 14px; font-weight: 700; fill: #252423; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__tree .tn-bad .t-v { fill: #a4262c; }
.uc-kpi-rf__tree .tn-good .t-v { fill: #13703a; }
.uc-kpi-rf__tree .tn-none .t-v, .uc-kpi-rf__tree .tn-none .t-l { fill: #8a8886; }
.uc-kpi-rf__tree .t-s { font-size: 10px; fill: #605e5c; }
.uc-kpi-rf__formula { margin-top: 6px; padding: 7px 10px; background: #faf9f8; border-left: 3px solid var(--accent2); font-size: 12px; line-height: 1.5; min-height: 20px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__vstrip { display: grid; grid-template-columns: 1fr; gap: 6px; }
.uc-kpi-rf__vstrip-bar { display: flex; height: 18px; background: #f3f2f1; }
.uc-kpi-rf__vstrip-bar span { display: block; height: 100%; }
.uc-kpi-rf .is-neg { background: #d13438; }
.uc-kpi-rf .is-neg2 { background: #ef9a9c; }
.uc-kpi-rf .is-pos { background: #1a9e4b; }
.uc-kpi-rf .is-pos2 { background: #9fd3b2; }
.uc-kpi-rf__vstrip-lg { display: flex; gap: 16px; flex-wrap: wrap; font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__vstrip-lg em { display: inline-block; width: 10px; height: 10px; margin-right: 5px; }
.uc-kpi-rf__vstrip-lg b { color: var(--ink); font-variant-numeric: tabular-nums; }
.uc-kpi-rf__vstrip-t { margin-left: auto; }
.uc-kpi-rf__tbars { margin-top: 12px; display: flex; flex-direction: column; gap: 9px; }
.uc-kpi-rf__tbar { display: grid; grid-template-columns: 170px 1fr 150px; gap: 10px; align-items: center; }
.uc-kpi-rf__tbar-l { font-size: 12px; }
.uc-kpi-rf__tbar-l i { display: block; font-size: 10.5px; color: var(--ink3); }
.uc-kpi-rf__tbar-t { position: relative; height: 16px; background: #f3f2f1; }
.uc-kpi-rf__tbar-t .is-before { position: absolute; left: 0; top: 0; bottom: 0; background: #d2d0ce; }
.uc-kpi-rf__tbar-t .is-after { position: absolute; left: 0; top: 4px; bottom: 4px; }
.uc-kpi-rf__tbar-t i { position: absolute; top: -3px; bottom: -3px; width: 2px; background: #252423; }
.uc-kpi-rf__tbar-v { text-align: right; font-size: 12px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__tbar-v s { color: var(--ink3); text-decoration: none; }
.uc-kpi-rf__tbar-v small { display: block; font-size: 10.5px; color: var(--ink3); }
.uc-kpi-rf__detailbtn { width: 100%; margin-top: 8px; padding: 8px; border: 1px dashed #a19f9d; background: #fff; color: var(--accent2); font-size: 12px; font-weight: 600; cursor: pointer; }
@media (max-width: 600px) {
  .uc-kpi-rf__tbar { grid-template-columns: 1fr; gap: 3px; }
  .uc-kpi-rf__tbar-v { text-align: left; }
}
.uc-kpi-rf__actions { margin-left: auto; align-self: center; display: flex; gap: 8px; flex-wrap: wrap; }
.uc-kpi-rf__actions .uc-kpi-rf__simbtn { margin-left: 0; }
.uc-kpi-rf__simbtn.is-solid { background: var(--accent2); color: #fff; }
.uc-kpi-rf__simbtn.is-solid:hover { background: #12284A; }
.uc-kpi-rf__namebtn { font-size: 11px; color: var(--accent); background: transparent; border: 1px solid #C3CFDC; padding: 2px 8px; cursor: pointer; }
.uc-kpi-rf__pack { display: none; }
@media print {
  @page { size: A4 portrait; margin: 13mm 12mm; }
  body > *:not(.uc-kpi-rf__pack) { display: none !important; }
  body { background: #fff !important; margin: 0 !important; }
  .uc-kpi-rf__pack { display: block !important; width: 100%; background: #fff; color: #1b1a19;
    font-family: 'Segoe UI', -apple-system, 'Helvetica Neue', Arial, sans-serif; font-size: 9.5pt; line-height: 1.4; -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  .uc-kpi-rf__tabs, .uc-kpi-rf__drawer, .uc-kpi-rf__veil { display: none !important; }
  .uc-kpi-rf__pack .pk-break { page-break-before: always; break-before: page; }
  .uc-kpi-rf__pack .pk-head { display: flex; justify-content: space-between; align-items: flex-start; border-bottom: 2px solid #1B365D; padding-bottom: 6pt; margin-bottom: 8pt; }
  .uc-kpi-rf__pack .pk-org { font-size: 8.5pt; color: #605e5c; text-transform: uppercase; letter-spacing: 0.5pt; }
  .uc-kpi-rf__pack .pk-title { font-size: 16pt; font-weight: 700; color: #1B365D; margin-top: 2pt; }
  .uc-kpi-rf__pack .pk-sub { font-size: 9pt; color: #605e5c; font-style: italic; }
  .uc-kpi-rf__pack .pk-stamp { border: 1.5pt solid #d9822b; color: #d9822b; font-weight: 700; font-size: 9pt; padding: 3pt 8pt; text-align: center; }
  .uc-kpi-rf__pack .pk-stamp small { font-weight: 400; font-size: 7.5pt; }
  .uc-kpi-rf__pack .pk-h { font-size: 11.5pt; font-weight: 700; margin: 10pt 0 5pt; color: #1b1a19; border-left: 3pt solid #1B365D; padding-left: 6pt; }
  .uc-kpi-rf__pack .pk-h i { font-weight: 400; color: #8a8886; font-size: 9pt; margin-left: 4pt; }
  .uc-kpi-rf__pack .pk-lead { background: #EEF2F6; border: 0.75pt solid #C3CFDC; padding: 7pt 9pt; font-size: 10pt; line-height: 1.55; }
  .uc-kpi-rf__pack .pk-stats { width: 100%; border-collapse: separate; border-spacing: 5pt; margin: 4pt -5pt 0; }
  .uc-kpi-rf__pack .pk-stats td { border: 0.75pt solid #c8c6c4; padding: 5pt 7pt; width: 33%; vertical-align: top; }
  .uc-kpi-rf__pack .pk-stats span { display: block; font-size: 8pt; color: #605e5c; }
  .uc-kpi-rf__pack .pk-stats b { display: block; font-size: 12.5pt; margin-top: 1pt; }
  .uc-kpi-rf__pack .pk-stats small { display: block; font-size: 7.5pt; color: #8a8886; }
  .uc-kpi-rf__pack .pk-table { width: 100%; border-collapse: collapse; font-size: 8.5pt; page-break-inside: auto; }
  .uc-kpi-rf__pack .pk-table tr { page-break-inside: avoid; break-inside: avoid; }
  .uc-kpi-rf__pack .pk-table th { background: #f3f2f1; border: 0.75pt solid #c8c6c4; padding: 3pt 5pt; text-align: right; font-weight: 600; font-size: 8pt; }
  .uc-kpi-rf__pack .pk-table td { border: 0.75pt solid #d2d0ce; padding: 3pt 5pt; text-align: right; vertical-align: top; }
  .uc-kpi-rf__pack .pk-table .l { text-align: left; }
  .uc-kpi-rf__pack .pk-table small { display: block; font-size: 7pt; color: #8a8886; }
  .uc-kpi-rf__pack .pk-good { background: #e7f4ec; }
  .uc-kpi-rf__pack .pk-warn { background: #fdf1e3; }
  .uc-kpi-rf__pack .pk-bad { background: #fbe9ea; color: #a4262c; font-weight: 700; }
  .uc-kpi-rf__pack .pk-txt-bad { color: #a4262c; }
  .uc-kpi-rf__pack .pk-note { font-size: 7.5pt; color: #8a8886; margin-top: 3pt; }
  .uc-kpi-rf__pack .pk-kpisum { display: flex; flex-wrap: wrap; gap: 4pt 14pt; font-size: 8.5pt; margin-bottom: 4pt; }
  .uc-kpi-rf__pack .pk-decide td { height: 26pt; }
  .uc-kpi-rf__pack .pk-box { display: inline-block; width: 9pt; height: 9pt; border: 0.75pt solid #605e5c; }
  .uc-kpi-rf__pack .pk-blank { min-width: 90pt; }
  .uc-kpi-rf__pack .pk-ul { margin: 0 0 4pt 14pt; padding: 0; font-size: 8.5pt; }
  .uc-kpi-rf__pack .pk-assume { width: 70%; }
  .uc-kpi-rf__pack .pk-sign { display: flex; gap: 12pt; margin-top: 18pt; }
  .uc-kpi-rf__pack .pk-sign div { flex: 1; border-top: 0.75pt solid #605e5c; padding-top: 4pt; height: 50pt; }
  .uc-kpi-rf__pack .pk-sign span { display: block; font-weight: 600; font-size: 8.5pt; }
  .uc-kpi-rf__pack .pk-sign i { font-size: 7.5pt; color: #8a8886; }
  .uc-kpi-rf__pack .pk-foot { margin-top: 10pt; font-size: 7pt; color: #a19f9d; text-align: center; }
}
.uc-kpi-rf__simbar { display: flex; flex-wrap: wrap; gap: 18px; align-items: flex-end; background: var(--card); border: 1px solid var(--line); padding: 10px 14px; margin-bottom: 8px; }
.uc-kpi-rf__simbar-r { margin-left: auto; }
.uc-kpi-rf__simbar .uc-kpi-rf__select { min-width: 180px; }
.uc-kpi-rf__en { font-weight: 400; font-style: italic; color: var(--ink3); font-size: 12px; margin-left: 4px; }
.uc-kpi-rf__gv { display: grid; grid-template-columns: 4fr 3fr 3fr; gap: 8px; margin-bottom: 8px; }
.uc-kpi-rf__gv-group { background: var(--card); border: 1px solid var(--line); padding: 8px 10px; min-width: 0; }
.uc-kpi-rf__gv-h { font-size: 12px; font-weight: 700; margin-bottom: 6px; }
.uc-kpi-rf__gv-h i { font-weight: 400; color: var(--ink3); margin-left: 4px; }
.uc-kpi-rf__gv-row { display: grid; grid-auto-flow: column; grid-auto-columns: minmax(0, 1fr); gap: 6px; }
.uc-kpi-rf__gv-c { border-left: 3px solid #c8c6c4; padding: 4px 8px; background: #faf9f8; min-width: 0; }
.uc-kpi-rf__gv-c.st-l-good { border-left-color: var(--good); }
.uc-kpi-rf__gv-c.st-l-warn { border-left-color: var(--warn); }
.uc-kpi-rf__gv-c.st-l-bad { border-left-color: var(--bad); }
.uc-kpi-rf__gv-c.is-key { background: #EEF2F6; border-left-color: var(--accent2); }
.uc-kpi-rf__gv-c span { display: block; font-size: 10.5px; color: var(--ink2); }
.uc-kpi-rf__gv-c b { display: block; font-size: 16px; font-weight: 700; font-variant-numeric: tabular-nums; margin-top: 2px; white-space: nowrap; }
.uc-kpi-rf__gv-c b small { font-size: 11px; font-weight: 400; color: var(--ink3); }
.uc-kpi-rf__gv-c > small { display: block; font-size: 10.5px; color: var(--ink3); line-height: 1.3; margin-top: 1px; }
.uc-kpi-rf__lv-h { font-size: 12px; font-weight: 700; margin: 8px 0 4px; }
.uc-kpi-rf__lv-h small { font-weight: 400; color: var(--ink3); }
.uc-kpi-rf__lv { width: 100%; border-collapse: collapse; font-size: 12px; }
.uc-kpi-rf__lv th { font-size: 10.5px; color: var(--ink2); font-weight: 600; text-align: right; padding: 3px 4px; border-bottom: 1px solid #c8c6c4; }
.uc-kpi-rf__lv td { padding: 3px 4px; border-bottom: 1px solid #f3f2f1; text-align: right; white-space: nowrap; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__lv td input[type=range] { width: 86px; vertical-align: middle; accent-color: #1B365D; }
.uc-kpi-rf__lv td em { display: inline-block; width: 40px; font-style: normal; font-weight: 700; text-align: right; }
.uc-kpi-rf__costs { display: flex; flex-direction: column; gap: 4px; }
.uc-kpi-rf__costs label { display: flex; justify-content: space-between; align-items: center; gap: 8px; font-size: 12px; }
.uc-kpi-rf__costs input { width: 90px; border: 1px solid #c8c6c4; padding: 3px 6px; text-align: right; font-size: 12px; }
.uc-kpi-rf__svg .g-money.is-good { fill: #1a9e4b; }
.uc-kpi-rf__goal { margin-top: 8px; }
.uc-kpi-rf__goal-need { display: flex; justify-content: space-between; gap: 8px; flex-wrap: wrap; padding: 6px 0; border-bottom: 1px solid var(--line); }
.uc-kpi-rf__goal-need span { font-size: 11.5px; color: var(--ink2); }
.uc-kpi-rf__goal-row { display: flex; justify-content: space-between; gap: 8px; padding: 6px 0; border-bottom: 1px solid #f3f2f1; font-size: 12.5px; }
.uc-kpi-rf__goal-row b { font-variant-numeric: tabular-nums; text-align: right; }
@media (max-width: 1100px) { .uc-kpi-rf__gv { grid-template-columns: 1fr; } }
@media (max-width: 600px) { .uc-kpi-rf__gv-row { grid-auto-flow: row; } .uc-kpi-rf__lv td input[type=range] { width: 64px; } }
.uc-kpi-rf__costhint { font-size: 11.5px; color: var(--ink2); margin-top: 6px; padding: 5px 8px; background: #faf9f8; border-left: 3px solid #c8c6c4; }
.uc-kpi-rf__spot { position: fixed; inset: 0; z-index: 40; background: rgba(16, 24, 36, 0.6); backdrop-filter: blur(4px); -webkit-backdrop-filter: blur(4px); display: flex; align-items: center; justify-content: center; padding: 2vh 2vw; animation: ucKpiFade 0.18s ease-out; }
.uc-kpi-rf__sp { width: 100%; max-width: 1440px; height: 100%; max-height: 96vh; background: #f3f2f1; display: flex; flex-direction: column; box-shadow: 0 24px 64px rgba(0, 0, 0, 0.35); animation: ucKpiRise 0.22s ease-out; }
@keyframes ucKpiFade { from { opacity: 0; } to { opacity: 1; } }
@keyframes ucKpiRise { from { opacity: 0; transform: translateY(12px) scale(0.985); } to { opacity: 1; transform: none; } }
.uc-kpi-rf__sp-head { display: flex; align-items: center; gap: 18px; padding: 12px 20px; background: #1B365D; color: #fff; }
.uc-kpi-rf__sp-titles { min-width: 0; }
.uc-kpi-rf__sp-kicker { font-size: 11px; letter-spacing: 0.6px; text-transform: uppercase; opacity: 0.75; }
.uc-kpi-rf__sp-title { font-size: 20px; font-weight: 600; letter-spacing: -0.2px; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.uc-kpi-rf__sp-types { margin-left: auto; display: inline-flex; border: 1px solid rgba(255, 255, 255, 0.4); }
.uc-kpi-rf__sp-types button { padding: 6px 14px; font-size: 12.5px; color: #fff; background: transparent; cursor: pointer; border-right: 1px solid rgba(255, 255, 255, 0.3); }
.uc-kpi-rf__sp-types button:last-child { border-right: 0; }
.uc-kpi-rf__sp-types button.is-on { background: #fff; color: #1B365D; font-weight: 600; }
.uc-kpi-rf__sp-x { background: transparent; color: #fff; font-size: 28px; line-height: 1; cursor: pointer; padding: 0 4px; }
.uc-kpi-rf__sp-body { flex: 1; min-height: 0; display: grid; grid-template-columns: 280px 1fr; }
.uc-kpi-rf__sp-rail { background: #fff; border-right: 1px solid var(--line); padding: 14px 16px; overflow-y: auto; }
.uc-kpi-rf__sp-rail-h { font-size: 13px; font-weight: 700; margin-bottom: 10px; }
.uc-kpi-rf__sp-rail-h i { font-weight: 400; color: var(--ink3); margin-left: 4px; }
.uc-kpi-rf__sp-f { margin-bottom: 14px; }
.uc-kpi-rf__sp-f > label { display: flex; justify-content: space-between; font-size: 11.5px; color: var(--ink2); margin-bottom: 5px; }
.uc-kpi-rf__sp-f > label b { color: var(--ink); font-size: 13px; }
.uc-kpi-rf__sp-opts { display: flex; flex-wrap: wrap; gap: 4px; }
.uc-kpi-rf__sp-opts.is-col { flex-direction: column; }
.uc-kpi-rf__sp-opts button { border: 1px solid #c8c6c4; background: #fff; padding: 5px 9px; font-size: 12px; cursor: pointer; text-align: left; }
.uc-kpi-rf__sp-opts button:hover { border-color: #1B365D; }
.uc-kpi-rf__sp-opts button.is-on { background: #1B365D; border-color: #1B365D; color: #fff; }
.uc-kpi-rf__sp-rail-note { font-size: 10.5px; color: var(--ink3); line-height: 1.45; border-top: 1px solid var(--line); padding-top: 10px; }
.uc-kpi-rf__sp-main { overflow-y: auto; padding: 14px 18px 20px; display: flex; flex-direction: column; gap: 10px; }
.uc-kpi-rf__sp-hero { background: #fff; border: 1px solid var(--line); padding: 14px 16px; }
.uc-kpi-rf__sp-bl { font-size: 15.5px; line-height: 1.55; color: var(--ink); }
.uc-kpi-rf__sp-bl-k { display: inline-block; background: #fff1d6; color: #8a5a00; font-size: 10.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.5px; padding: 2px 7px; margin-right: 8px; vertical-align: 2px; }
.uc-kpi-rf__sp-kpis { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-top: 12px; }
.uc-kpi-rf__sp-kpi { position: relative; border-top: 4px solid #c8c6c4; background: #faf9f8; padding: 10px 12px 12px; min-width: 0; }
.uc-kpi-rf__sp-kpi.is-bad { border-top-color: var(--bad); }
.uc-kpi-rf__sp-kpi.is-good { border-top-color: var(--good); }
.uc-kpi-rf__sp-kpi.is-warn { border-top-color: var(--warn); }
.uc-kpi-rf__sp-kpi-k { font-size: 12px; color: var(--ink2); font-weight: 600; }
.uc-kpi-rf__sp-kpi-k i { display: block; font-weight: 400; font-size: 10.5px; color: var(--ink3); }
.uc-kpi-rf__sp-kpi-v { font-size: clamp(20px, 2.05vw, 30px); font-weight: 700; letter-spacing: -0.5px; margin-top: 6px; font-variant-numeric: tabular-nums; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.uc-kpi-rf__sp-kpi.is-bad .uc-kpi-rf__sp-kpi-v { color: #a4262c; }
.uc-kpi-rf__sp-kpi.is-good .uc-kpi-rf__sp-kpi-v { color: #13703a; }
.uc-kpi-rf__sp-kpi-s { font-size: 11.5px; color: var(--ink3); margin-top: 2px; }
.uc-kpi-rf__sp-kpi .uc-kpi-rf__src-tag { display: inline-block; margin-top: 6px; }
.uc-kpi-rf__sp-card { background: #fff; border: 1px solid var(--line); padding: 12px 14px; min-width: 0; }
.uc-kpi-rf__sp-2col { display: grid; grid-template-columns: 1fr 1fr; gap: 10px; }
.uc-kpi-rf__sp-2col.is-3 { grid-template-columns: repeat(3, minmax(0, 1fr)); }
.uc-kpi-rf__sp-value { display: flex; align-items: baseline; gap: 10px; margin-bottom: 8px; }
.uc-kpi-rf__sp-value-total { font-size: 28px; font-weight: 700; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__sp-value-lbl { font-size: 12px; color: var(--ink3); }
.uc-kpi-rf__vstrip-bar.is-big { height: 26px; margin-bottom: 8px; }
.uc-kpi-rf__tbar-t.is-big { height: 22px; }
.uc-kpi-rf__tbar-t.is-big .is-after { top: 6px; bottom: 6px; }
.uc-kpi-rf__tree.is-big .t-head { font-size: 11.5px; }
.uc-kpi-rf__tree.is-big .t-l { font-size: 13px; }
.uc-kpi-rf__tree.is-big .t-en { font-size: 10.5px; }
.uc-kpi-rf__tree.is-big .t-v { font-size: 18px; }
.uc-kpi-rf__tree.is-big .t-s { font-size: 11.5px; }
.uc-kpi-rf__tree.is-big .t-edge { stroke-dasharray: 1400; stroke-dashoffset: 1400; animation: ucKpiFlow 0.9s ease-out forwards; }
.uc-kpi-rf__tree.is-big .t-edge.is-dash { stroke-dasharray: 6 5; stroke-dashoffset: 0; animation: ucKpiDash 1.2s linear infinite; }
.uc-kpi-rf__tree.is-big .t-node { animation: ucKpiFade 0.4s ease-out both; }
@keyframes ucKpiFlow { to { stroke-dashoffset: 0; } }
@keyframes ucKpiDash { to { stroke-dashoffset: -22; } }
@media (prefers-reduced-motion: reduce) {
  .uc-kpi-rf__spot, .uc-kpi-rf__sp, .uc-kpi-rf__tree.is-big .t-node { animation: none; }
  .uc-kpi-rf__tree.is-big .t-edge, .uc-kpi-rf__tree.is-big .t-edge.is-dash { animation: none; stroke-dashoffset: 0; }
}
@media (max-width: 1100px) {
  .uc-kpi-rf__sp-body { grid-template-columns: 1fr; }
  .uc-kpi-rf__sp-rail { border-right: 0; border-bottom: 1px solid var(--line); max-height: 34vh; }
  .uc-kpi-rf__sp-kpis { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .uc-kpi-rf__sp-2col, .uc-kpi-rf__sp-2col.is-3 { grid-template-columns: 1fr; }
  .uc-kpi-rf__sp-head { flex-wrap: wrap; }
  .uc-kpi-rf__sp-types { margin-left: 0; order: 3; }
}
@media (max-width: 600px) {
  .uc-kpi-rf__spot { padding: 0; }
  .uc-kpi-rf__sp { max-height: none; }
  .uc-kpi-rf__sp-kpi-v { font-size: 20px; }
  .uc-kpi-rf__sp-title { white-space: normal; font-size: 16px; }
}
.uc-kpi-rf__sp-kpi-from { font-size: 14px; font-weight: 500; color: var(--ink3); margin-right: 6px; letter-spacing: 0; }
.uc-kpi-rf__flow { display: grid; grid-template-columns: 420px 1fr; gap: 16px; align-items: start; }
.uc-kpi-rf__flow-q { min-width: 0; }
.uc-kpi-rf__flow-t { min-width: 0; overflow-x: auto; }
.uc-kpi-rf__svg .q-good { fill: #eef7f1; }
.uc-kpi-rf__svg .q-warn { fill: #fdf6ec; }
.uc-kpi-rf__svg .q-bad { fill: #fcecec; }
.uc-kpi-rf__svg .q-lbl { font-size: 11px; font-weight: 600; fill: #605e5c; }
.uc-kpi-rf__svg .q-lbl-bad { fill: #a4262c; }
.uc-kpi-rf__svg .q-axis2 { stroke: #252423; stroke-width: 1; stroke-dasharray: 4 3; }
.uc-kpi-rf__svg .q-dot { stroke: #fff; stroke-width: 2; opacity: 0.92; }
.uc-kpi-rf__svg .q-tot { fill: #1a9e4b; }
.uc-kpi-rf__svg .q-bu, .uc-kpi-rf__svg .q-thieu { fill: #d9822b; }
.uc-kpi-rf__svg .q-xau { fill: #d13438; }
.uc-kpi-rf__svg .q-name { font-size: 10.5px; font-weight: 600; fill: #252423; }
.uc-kpi-rf__qc { margin-top: 12px; border: 1px solid var(--line); padding: 10px 12px; background: #faf9f8; }
.uc-kpi-rf__qc-h { font-size: 13px; font-weight: 600; margin-bottom: 8px; }
.uc-kpi-rf__qc-in { display: flex; flex-wrap: wrap; gap: 10px 16px; align-items: flex-end; }
.uc-kpi-rf__qc-in label { display: flex; flex-direction: column; gap: 3px; font-size: 11px; color: var(--ink2); }
.uc-kpi-rf__qc-in input[type=number] { width: 70px; border: 1px solid #c8c6c4; padding: 4px 6px; font-size: 13px; text-align: right; }
.uc-kpi-rf__qc-out { margin-top: 10px; padding: 10px 12px; background: #fff; border-left: 4px solid #c8c6c4; }
.uc-kpi-rf__qc-out.is-good { border-left-color: var(--good); }
.uc-kpi-rf__qc-out.is-warn { border-left-color: var(--warn); }
.uc-kpi-rf__qc-out.is-bad { border-left-color: var(--bad); }
.uc-kpi-rf__qc-verdict { font-size: 18px; font-weight: 700; }
.uc-kpi-rf__qc-out.is-good .uc-kpi-rf__qc-verdict { color: #13703a; }
.uc-kpi-rf__qc-out.is-warn .uc-kpi-rf__qc-verdict { color: #a35a12; }
.uc-kpi-rf__qc-out.is-bad .uc-kpi-rf__qc-verdict { color: #a4262c; }
.uc-kpi-rf__qc-why { font-size: 12.5px; color: var(--ink2); margin-top: 3px; line-height: 1.45; }
.uc-kpi-rf__qc-nums { display: flex; flex-wrap: wrap; gap: 6px 18px; margin-top: 8px; font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__qc-nums b { color: var(--ink); font-variant-numeric: tabular-nums; }
@media (max-width: 1100px) { .uc-kpi-rf__flow { grid-template-columns: 1fr; } }
.uc-kpi-rf__tree.is-v2 .t-edge { stroke: #b3b0ad; opacity: 1; animation: none !important; stroke-dasharray: none !important; stroke-linecap: round; }
.uc-kpi-rf__tree.is-v2 .t-edge.is-hl { stroke: #1B365D; }
.uc-kpi-rf__tree.is-v2 .t-edge.is-dim { opacity: 0.18; }
.uc-kpi-rf__tree.is-v2 .t-node { animation: none !important; }
.uc-kpi-rf__tree.is-v2 .t-box { fill: #ffffff; stroke: #c8c6c4; stroke-width: 1; stroke-dasharray: none; }
.uc-kpi-rf__tree.is-v2 .is-est .t-box { fill: #f5f4f2; }
.uc-kpi-rf__tree.is-v2 .t-bar { fill: #c8c6c4; }
.uc-kpi-rf__tree.is-v2 .is-event .t-bar { fill: #1B365D; }
.uc-kpi-rf__tree.is-v2 .is-event .t-box { stroke: #1B365D; }
.uc-kpi-rf__tree.is-v2 .ta-bad .t-bar { fill: #d13438; }
.uc-kpi-rf__tree.is-v2 .ta-bad .t-box { stroke: #d13438; }
.uc-kpi-rf__tree.is-v2 .ta-good .t-bar { fill: #1a9e4b; }
.uc-kpi-rf__tree.is-v2 .ta-good .t-box { stroke: #1a9e4b; }
.uc-kpi-rf__tree.is-v2 .t-l { font-size: 12.5px; font-weight: 600; fill: #605e5c; }
.uc-kpi-rf__tree.is-v2 .t-v { font-size: 18px; font-weight: 700; fill: #1b1a19; }
.uc-kpi-rf__tree.is-v2 .is-event .t-v { fill: #1B365D; }
.uc-kpi-rf__tree.is-v2 .ta-bad .t-v { fill: #a4262c; }
.uc-kpi-rf__tree.is-v2 .ta-good .t-v { fill: #13703a; }
.uc-kpi-rf__tree.is-v2 .t-s { font-size: 11.5px; fill: #8a8886; }
.uc-kpi-rf__tree.is-v2 .t-node.is-hover .t-box { stroke: #1B365D; stroke-width: 2; }
.uc-kpi-rf__legend2 .lg2-real { border: 1px solid #c8c6c4; background: #fff; }
.uc-kpi-rf__legend2 .lg2-est { border: 1px solid #c8c6c4; background: #f5f4f2; }
.uc-kpi-rf__legend2 .lg2-bad { border: 1px solid #d13438; border-left: 4px solid #d13438; background: #fff; }
.uc-kpi-rf__legend2 .lg2-good { border: 1px solid #1a9e4b; border-left: 4px solid #1a9e4b; background: #fff; }
.uc-kpi-rf__gaps { margin-top: 6px; font-size: 11.5px; color: var(--ink3); line-height: 1.45; }
.uc-kpi-rf__gaps b { color: var(--ink2); }
.uc-kpi-rf__sp-kpi.is-none { border-top-color: #c8c6c4; }
.uc-kpi-rf__sp-kpi.is-none .uc-kpi-rf__sp-kpi-v { color: #1b1a19; }
.uc-kpi-rf__spot, .uc-kpi-rf__sp { animation-duration: 0.15s; }
/* ---- compact spotlight (laptop + iPad) ---- */
.uc-kpi-rf__spot { padding: 1.2vh 1.2vw; }
.uc-kpi-rf__sp { max-height: 97vh; }
.uc-kpi-rf__sp-head { padding: 8px 14px; gap: 12px; }
.uc-kpi-rf__sp-kicker { font-size: 10px; }
.uc-kpi-rf__sp-title { font-size: 16px; }
.uc-kpi-rf__sp-types button { padding: 4px 10px; font-size: 12px; }
.uc-kpi-rf__sp-x { font-size: 22px; }
.uc-kpi-rf__sp-body { grid-template-columns: 220px 1fr; }
.uc-kpi-rf__sp-rail { padding: 10px 12px; }
.uc-kpi-rf__sp-rail-h { font-size: 12px; margin-bottom: 6px; }
.uc-kpi-rf__sp-f { margin-bottom: 9px; }
.uc-kpi-rf__sp-f > label { font-size: 11px; margin-bottom: 3px; }
.uc-kpi-rf__sp-f > label b { font-size: 12px; }
.uc-kpi-rf__sp-opts { gap: 3px; }
.uc-kpi-rf__sp-opts button { padding: 3px 7px; font-size: 11.5px; }
.uc-kpi-rf__sp-f .uc-kpi-rf__select { padding: 3px 5px; font-size: 11.5px; }
.uc-kpi-rf__sp-rail-note { font-size: 10px; padding-top: 6px; }
.uc-kpi-rf__sp-main { padding: 8px 10px 12px; gap: 8px; }
.uc-kpi-rf__sp-hero { padding: 8px 10px; }
.uc-kpi-rf__sp-bl { font-size: 13px; line-height: 1.45; }
.uc-kpi-rf__sp-bl-k { font-size: 9.5px; padding: 1px 6px; margin-right: 6px; }
.uc-kpi-rf__sp-kpis { gap: 6px; margin-top: 8px; }
.uc-kpi-rf__sp-kpi { border-top-width: 3px; padding: 6px 9px 7px; }
.uc-kpi-rf__sp-kpi-k { font-size: 11px; }
.uc-kpi-rf__sp-kpi-v { font-size: clamp(16px, 1.55vw, 22px); margin-top: 2px; letter-spacing: -0.3px; }
.uc-kpi-rf__sp-kpi-from { font-size: 11.5px; }
.uc-kpi-rf__sp-kpi-s { font-size: 10.5px; margin-top: 1px; }
.uc-kpi-rf__sp-kpi .uc-kpi-rf__src-tag { margin-top: 3px; font-size: 9.5px; padding: 0 4px; }
.uc-kpi-rf__sp-card { padding: 8px 10px; }
.uc-kpi-rf__sp .uc-kpi-rf__dr-h2 { font-size: 12.5px; margin-bottom: 4px; }
.uc-kpi-rf__sp .uc-kpi-rf__legend2 { gap: 8px; font-size: 10px; }
.uc-kpi-rf__tree.is-big { max-width: 940px; margin: 0 auto; }
.uc-kpi-rf__tree.is-v2 .t-head { font-size: 10px; }
.uc-kpi-rf__tree.is-v2 .t-l { font-size: 11px; }
.uc-kpi-rf__tree.is-v2 .t-v { font-size: 15px; }
.uc-kpi-rf__tree.is-v2 .t-s { font-size: 10px; }
.uc-kpi-rf__sp .uc-kpi-rf__formula { padding: 5px 8px; font-size: 11.5px; margin-top: 4px; }
.uc-kpi-rf__sp .uc-kpi-rf__gaps { font-size: 10.5px; margin-top: 4px; }
.uc-kpi-rf__sp-2col { gap: 8px; }
.uc-kpi-rf__sp-value { margin-bottom: 4px; }
.uc-kpi-rf__sp-value-total { font-size: 20px; }
.uc-kpi-rf__vstrip-bar.is-big { height: 16px; margin-bottom: 4px; }
.uc-kpi-rf__sp .uc-kpi-rf__vstrip-lg { font-size: 11px; gap: 10px; }
.uc-kpi-rf__sp .uc-kpi-rf__tbars { margin-top: 4px; gap: 6px; }
.uc-kpi-rf__sp .uc-kpi-rf__tbar { grid-template-columns: 150px 1fr 120px; gap: 8px; }
.uc-kpi-rf__sp .uc-kpi-rf__tbar-l { font-size: 11.5px; }
.uc-kpi-rf__tbar-t.is-big { height: 14px; }
.uc-kpi-rf__tbar-t.is-big .is-after { top: 4px; bottom: 4px; }
.uc-kpi-rf__sp .uc-kpi-rf__tbar-v { font-size: 11.5px; }
.uc-kpi-rf__sp .uc-kpi-rf__route { gap: 4px 10px; }
.uc-kpi-rf__sp .uc-kpi-rf__route b { font-size: 12px; }
.uc-kpi-rf__sp .uc-kpi-rf__drv { padding: 4px 0; }
.uc-kpi-rf__sp .uc-kpi-rf__drv-l { font-size: 12px; }
.uc-kpi-rf__sp .uc-kpi-rf__who { grid-template-columns: 170px 1fr; padding: 4px 0; font-size: 12px; }
.uc-kpi-rf__sp .uc-kpi-rf__dr-note, .uc-kpi-rf__sp .uc-kpi-rf__dr-foot { font-size: 10.5px; margin-top: 4px; }
.uc-kpi-rf__sp .uc-kpi-rf__detailbtn { padding: 6px; margin-top: 0; }
/* iPad portrait / landscape narrow: assumptions become a compact top bar */
@media (max-width: 1100px) {
  .uc-kpi-rf__spot { padding: 0; }
  .uc-kpi-rf__sp { max-height: 100vh; height: 100vh; }
  .uc-kpi-rf__sp-head { flex-wrap: nowrap; }
  .uc-kpi-rf__sp-types { order: 0; margin-left: auto; }
  .uc-kpi-rf__sp-title { font-size: 14.5px; min-width: 0; }
  .uc-kpi-rf__sp-types { flex-shrink: 0; }
  .uc-kpi-rf__sp-types button { white-space: nowrap; padding: 4px 8px; }
  .uc-kpi-rf__sp-body { grid-template-columns: 1fr; grid-template-rows: auto 1fr; }
  .uc-kpi-rf__sp-rail { max-height: none; border-right: 0; border-bottom: 1px solid var(--line); display: flex; flex-wrap: wrap; align-items: flex-start; gap: 6px 14px; padding: 6px 10px; }
  .uc-kpi-rf__sp-rail-h, .uc-kpi-rf__sp-rail-note { display: none; }
  .uc-kpi-rf__sp-f { margin-bottom: 0; min-width: 0; }
  .uc-kpi-rf__sp-opts.is-col { flex-direction: row; flex-wrap: wrap; max-width: 520px; }
  .uc-kpi-rf__sp-f .uc-kpi-rf__range { width: 150px; }
  .uc-kpi-rf__sp-kpis { grid-template-columns: repeat(4, minmax(0, 1fr)); }
  .uc-kpi-rf__sp-kpi-v { font-size: 17px; }
  .uc-kpi-rf__sp-2col { grid-template-columns: 1fr 1fr; }
  .uc-kpi-rf__sp-2col.is-3 { grid-template-columns: 1fr; }
  .uc-kpi-rf__sp .uc-kpi-rf__tbar { grid-template-columns: 1fr; gap: 2px; }
  .uc-kpi-rf__sp .uc-kpi-rf__tbar-v { text-align: left; }
}
@media (max-width: 760px) {
  .uc-kpi-rf__sp-head { flex-wrap: wrap; }
  .uc-kpi-rf__sp-types { order: 3; margin-left: 0; }
  .uc-kpi-rf__sp-kpis { grid-template-columns: repeat(2, minmax(0, 1fr)); }
  .uc-kpi-rf__sp-2col { grid-template-columns: 1fr; }
}
/* enrollment map (page 6) */
.uc-kpi-rf__sankey { width: 100%; height: auto; display: block; font-family: inherit; }
.uc-kpi-rf__sankey .s-head { font-size: 10px; fill: #8a8886; font-weight: 600; letter-spacing: 0.3px; text-transform: uppercase; }
.uc-kpi-rf__sankey .s-link { fill: #A9BACC; opacity: 0.55; transition: opacity 0.15s; }
.uc-kpi-rf__sankey .s-link.sl-src { fill: #8FA6BF; }
.uc-kpi-rf__sankey .s-link.sl-out { fill: #6B88A8; }
.uc-kpi-rf__sankey .s-link.sl-good { fill: #1a9e4b; opacity: 0.45; }
.uc-kpi-rf__sankey .s-link.sl-care { fill: #3A6EA5; opacity: 0.4; }
.uc-kpi-rf__sankey .s-link.sl-bad { fill: #d13438; opacity: 0.35; }
.uc-kpi-rf__sankey .s-link.sl-na { fill: #c8c6c4; opacity: 0.6; }
.uc-kpi-rf__sankey .s-link.is-est { opacity: 1; }
.uc-kpi-rf__sankey .s-link.is-hl { opacity: 0.75; }
.uc-kpi-rf__sankey .s-link.is-est.is-hl { opacity: 1; }
.uc-kpi-rf__sankey .s-link.is-dim { opacity: 0.07; }
.uc-kpi-rf__sankey .s-node { cursor: pointer; transition: opacity 0.15s; }
.uc-kpi-rf__sankey .s-node rect { fill: #1B365D; }
.uc-kpi-rf__sankey .sn-src rect { fill: #6B88A8; }
.uc-kpi-rf__sankey .sn-good rect { fill: #1a9e4b; }
.uc-kpi-rf__sankey .sn-care rect { fill: #3A6EA5; }
.uc-kpi-rf__sankey .sn-bad rect { fill: #d13438; }
.uc-kpi-rf__sankey .sn-na rect { fill: #a19f9d; }
.uc-kpi-rf__sankey .sn-out rect { fill: #3A6EA5; }
.uc-kpi-rf__sankey .is-ph rect { fill: #c8c6c4; }
.uc-kpi-rf__sankey .is-ph .s-l { fill: #8a8886; font-weight: 400; font-style: italic; }
.uc-kpi-rf__sankey .s-node.is-dim { opacity: 0.3; }
.uc-kpi-rf__sankey .s-l { font-size: 11px; font-weight: 600; fill: #252423; paint-order: stroke; stroke: #fff; stroke-width: 3px; stroke-linejoin: round; }
.uc-kpi-rf__sankey .s-v { font-weight: 700; fill: #1B365D; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__sankey .sn-bad .s-v { fill: #a4262c; }
.uc-kpi-rf__sankey .sn-good .s-v { fill: #13703a; }
.uc-kpi-rf__sankey .sn-na .s-v, .uc-kpi-rf__sankey .is-ph .s-v { fill: #8a8886; }
.uc-kpi-rf__legend2 .lg-flow { border: 0; height: 8px; background: #8FA6BF; opacity: 0.8; }
.uc-kpi-rf__legend2 .lg-flow.is-est { background: repeating-linear-gradient(45deg, rgba(209, 52, 56, 0.55) 0 2px, rgba(209, 52, 56, 0.06) 2px 5px); opacity: 1; }
.uc-kpi-rf__legend2 .lg-ph { width: 2px; height: 10px; border: 0; background: #c8c6c4; }
.uc-kpi-rf__legend2 .lg-flow.is-out { background: #6B88A8; }
.uc-kpi-rf__pct { display: inline-flex; align-items: center; gap: 2px; }
.uc-kpi-rf__pct input { width: 46px; border: 1px solid #c8c6c4; padding: 2px 4px; text-align: right; font-size: 12px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__table tr.is-mute td { color: var(--ink3); }
.uc-kpi-rf__mapev { display: grid; grid-template-columns: 1fr 1fr; gap: 6px; }
.uc-kpi-rf__mapev div { border: 1px solid var(--line); border-left: 3px solid var(--warn); padding: 4px 8px; }
.uc-kpi-rf__mapev b { display: block; font-size: 15px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__mapev span { font-size: 11px; color: var(--ink2); }
@media (max-width: 900px) {
    .uc-kpi-rf__sankey .s-l { font-size: 12.5px; }
  .uc-kpi-rf__sankey .s-head { font-size: 11px; }
}
.uc-kpi-rf__sankey .s-link.is-dim { opacity: 0.07; }
.uc-kpi-rf__stat.is-gap { border-left: 3px dashed #a19f9d; background: #faf9f8; }
.uc-kpi-rf__stat.is-focus { box-shadow: 0 0 0 2px var(--accent2) inset; }
.uc-kpi-rf__flowseg button { font-weight: 600; }
.uc-kpi-rf__flowt { margin-right: auto; }
.uc-kpi-rf__pool td:first-child { white-space: normal; min-width: 140px; }
.uc-kpi-rf__pool-act b { font-weight: 600; }
.uc-kpi-rf__pool-act small { white-space: nowrap; overflow: hidden; text-overflow: ellipsis; max-width: 230px; }
.uc-kpi-rf__est { color: var(--warn) !important; font-style: italic; }
.uc-kpi-rf__stackcol { display: flex; flex-direction: column; gap: 6px; min-width: 0; }
.uc-kpi-rf__stackcol > .uc-kpi-rf__visual { flex: 0 0 auto; }
.uc-kpi-rf__stackcol > .uc-kpi-rf__visual:last-child { flex: 1 1 auto; }
.uc-kpi-rf__empty { background: #faf9f8; border-style: dashed; }
.uc-kpi-rf__empty .uc-kpi-rf__src { margin-top: 6px; }
.uc-kpi-rf__hb { width: 12px; height: 12px; vertical-align: -2px; margin-right: 6px; flex-shrink: 0; }
.uc-kpi-rf__hb .hb-o { fill: #fff; stroke: #1B365D; stroke-width: 1.2; }
.uc-kpi-rf__hb .hb-f { fill: #1B365D; }
.uc-kpi-rf__legend2 .uc-kpi-rf__hb { margin-right: 4px; }
.uc-kpi-rf__hbcell { white-space: nowrap !important; }
.uc-kpi-rf__fieldlist { margin-top: 8px; font-size: 12px; line-height: 1.5; }
.uc-kpi-rf__fieldlist p { margin: 0 0 2px; }
@media (max-width: 900px) { .uc-kpi-rf__stackcol { grid-column: span 12; } }
/* competitive benchmark (page 7) */
.uc-kpi-rf__bmbar { display: flex; align-items: flex-end; justify-content: space-between; gap: 12px; flex-wrap: wrap; background: var(--card); border: 1px solid var(--line); padding: 6px 10px; margin-bottom: 6px; }
.uc-kpi-rf__legend2 .lg-src { width: 10px; height: 10px; border-radius: 50%; border: 1.5px solid #3A6EA5; background: #fff; }
.uc-kpi-rf__legend2 .lg-src.cong { background: #6B88A8; border-color: #6B88A8; }
.uc-kpi-rf__legend2 .lg-src.tong { background: #D3DCE6; }
.uc-kpi-rf__legend2 .lg-src.gia { border-style: dashed; }
.uc-kpi-rf__pos { width: 100%; height: auto; display: block; font-family: inherit; }
.uc-kpi-rf__pos .p-bg { fill: #fff; stroke: #e1dfdd; }
.uc-kpi-rf__pos .p-grid { stroke: #f3f2f1; }
.uc-kpi-rf__pos .p-ax { font-size: 10px; fill: #8a8886; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__pos .p-axt { font-size: 10px; fill: #605e5c; font-weight: 600; }
.uc-kpi-rf__pos .p-med { stroke: #8a8886; stroke-dasharray: 4 3; }
.uc-kpi-rf__pos .p-quad { font-size: 10px; fill: #a19f9d; font-weight: 600; text-transform: uppercase; letter-spacing: 0.3px; }
.uc-kpi-rf__pos .p-pt { cursor: pointer; transition: opacity 0.15s; }
.uc-kpi-rf__pos .p-pt circle { fill: #D3DCE6; fill-opacity: 0.8; stroke: #3A6EA5; stroke-width: 1.2; }
.uc-kpi-rf__pos .p-pt.is-cong circle { fill: #6B88A8; fill-opacity: 0.75; }
.uc-kpi-rf__pos .p-pt.is-gia circle { fill: #fff; fill-opacity: 0.6; stroke-dasharray: 3 2; }
.uc-kpi-rf__pos .p-pt.is-self circle { fill: #1B365D; fill-opacity: 0.9; stroke: #1B365D; stroke-dasharray: 3 2; }
.uc-kpi-rf__pos .p-pt.is-dim { opacity: 0.25; }
.uc-kpi-rf__pos .p-lead { stroke: #a19f9d; stroke-width: 0.8; }
.uc-kpi-rf__pos .p-l { font-size: 11px; font-weight: 600; fill: #252423; paint-order: stroke; stroke: #fff; stroke-width: 3px; stroke-linejoin: round; }
.uc-kpi-rf__pos .is-self .p-l { fill: #1B365D; font-weight: 700; }
.uc-kpi-rf__bmrank { display: flex; flex-direction: column; gap: 10px; margin-top: 4px; }
.uc-kpi-rf__bmrank-row { display: grid; grid-template-columns: 96px 1fr 84px; gap: 8px; align-items: center; }
.uc-kpi-rf__bmrank-l { font-weight: 600; font-size: 12px; }
.uc-kpi-rf__bmrank-l small, .uc-kpi-rf__bmrank-v small { display: block; font-size: 10px; color: var(--ink3); font-weight: 400; }
.uc-kpi-rf__bmrank-t { position: relative; height: 18px; background: #f3f2f1; }
.uc-kpi-rf__bmrank-t .is-range { position: absolute; top: 6px; height: 6px; background: #C3CFDC; }
.uc-kpi-rf__bmrank-t .is-med { position: absolute; top: 1px; bottom: 1px; width: 0; border-left: 2px dashed #605e5c; }
.uc-kpi-rf__bmrank-t .is-self { position: absolute; top: 2px; width: 12px; height: 14px; margin-left: -6px; background: #1B365D; }
.uc-kpi-rf__bmrank-v { text-align: right; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__bmkey { display: flex; flex-wrap: wrap; gap: 4px 12px; font-size: 10.5px; color: var(--ink2); margin-top: 8px; }
.uc-kpi-rf__bmkey em { display: inline-block; margin-right: 4px; vertical-align: -1px; }
.uc-kpi-rf__bmkey .k-range { width: 14px; height: 6px; background: #C3CFDC; }
.uc-kpi-rf__bmkey .k-med { width: 0; height: 10px; border-left: 2px dashed #605e5c; }
.uc-kpi-rf__bmkey .k-self { width: 8px; height: 10px; background: #1B365D; }
.uc-kpi-rf__bmtable tr.is-self td { background: #EEF2F6; }
.uc-kpi-rf__bmtable tr.is-off td { color: var(--ink3); }
.uc-kpi-rf__bmtable td { white-space: normal; vertical-align: top; }
.uc-kpi-rf__bmtable td:first-child { min-width: 170px; }
.uc-kpi-rf__bmsrc { font-size: 11px; color: var(--ink2); max-width: 240px; }
.uc-kpi-rf__bmtable td:nth-child(2) { white-space: nowrap; }
.uc-kpi-rf__bmtable td small { white-space: nowrap; }
.uc-kpi-rf__table td small.bm-cong { color: var(--good); }
.uc-kpi-rf__table td small.bm-tong { color: #3A6EA5; }
.uc-kpi-rf__table td small.bm-gia { color: var(--warn); font-style: italic; }
.uc-kpi-rf__table td small.bm-that { color: var(--good); }
.uc-kpi-rf__lvdot { display: inline-block; min-width: 22px; text-align: center; font-size: 9.5px; font-weight: 700; padding: 1px 2px; margin-right: 2px; border: 1px solid #e1dfdd; color: #c8c6c4; }
.uc-kpi-rf__lvdot.is-on { background: #1B365D; border-color: #1B365D; color: #fff; }
.uc-kpi-rf__hbar-t span.is-hatch { background: repeating-linear-gradient(45deg, #6B88A8 0 2px, #EEF2F6 2px 5px); }
.uc-kpi-rf__bmplan { display: flex; flex-direction: column; }
.uc-kpi-rf__bmplan div { padding: 5px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__bmplan b { display: block; font-size: 12px; }
.uc-kpi-rf__bmplan span { display: block; font-size: 11.5px; color: var(--ink2); }
.uc-kpi-rf__bmplan small { display: block; font-size: 10.5px; color: var(--ink3); }
/* KPI dictionary (page 9) and priority operations (page 8) */
.uc-kpi-rf__dictsearch { display: flex; gap: 8px; align-items: center; flex-wrap: wrap; }
.uc-kpi-rf__dictsearch input { width: 260px; max-width: 100%; border: 1px solid #c8c6c4; padding: 4px 8px; font-size: 12px; background: #fff; }
.uc-kpi-rf__dicttable td { white-space: normal; vertical-align: top; }
.uc-kpi-rf__dicttable td:first-child, .uc-kpi-rf__dicttable td:nth-child(4) { white-space: nowrap; }
.uc-kpi-rf__dicttable td:nth-child(2) { min-width: 170px; }
.uc-kpi-rf__dicttable tbody tr { cursor: pointer; }
.uc-kpi-rf__dicttable tr.is-sel td { background: #EEF2F6; }
.uc-kpi-rf__dicttable tr.is-sel td:first-child { box-shadow: inset 3px 0 0 #1B365D; }
.uc-kpi-rf__mode { display: inline-block; font-size: 10.5px; font-weight: 600; padding: 1px 6px; border: 1px solid; white-space: nowrap; }
.uc-kpi-rf__mode.m-tay { color: var(--warn); border-color: #f0c493; background: #fdf6ee; }
.uc-kpi-rf__mode.m-ban { color: #3A6EA5; border-color: #B7C6D6; background: #EEF2F6; }
.uc-kpi-rf__mode.m-tu { color: var(--good); border-color: #9fd3b2; background: #f2faf5; }
.uc-kpi-rf__arrow { color: var(--ink3); margin: 0 4px; }
.uc-kpi-rf__dictd { align-self: start; position: sticky; top: 8px; }
.uc-kpi-rf__dictadd { font-size: 11px; color: var(--warn); font-style: italic; margin: -2px 0 6px; }
.uc-kpi-rf__dl { display: grid; grid-template-columns: 112px 1fr; gap: 0; margin: 0; font-size: 12px; }
.uc-kpi-rf__dl dt { color: var(--ink2); padding: 4px 8px 4px 0; border-bottom: 1px solid #f3f2f1; font-size: 11px; }
.uc-kpi-rf__dl dd { margin: 0; padding: 4px 0; border-bottom: 1px solid #f3f2f1; line-height: 1.4; }
.uc-kpi-rf__dl dd.is-muted { color: var(--ink3); }
.uc-kpi-rf__dictflow { display: grid; grid-template-columns: repeat(5, minmax(0, 1fr)); gap: 4px; margin-top: 10px; }
.uc-kpi-rf__dictflow .df-step { border-top: 3px solid #d2d0ce; padding-top: 4px; min-width: 0; }
.uc-kpi-rf__dictflow .df-step i { font-style: normal; font-size: 10px; font-weight: 700; color: var(--ink3); }
.uc-kpi-rf__dictflow .df-step b { display: block; font-size: 11px; line-height: 1.3; }
.uc-kpi-rf__dictflow .df-step span { display: block; font-size: 10px; color: var(--ink3); line-height: 1.3; overflow: hidden; text-overflow: ellipsis; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; }
.uc-kpi-rf__dictflow .df-step.is-done { border-top-color: #1B365D; }
.uc-kpi-rf__dictflow .df-step.is-doing { border-top-color: #A9BACC; }
.uc-kpi-rf__opsg { margin-bottom: 6px; }
.uc-kpi-rf__opssig { display: flex; flex-wrap: wrap; align-items: center; gap: 4px 8px; font-size: 11.5px; margin-bottom: 8px; }
.uc-kpi-rf__opssig b { font-size: 11px; color: var(--ink2); text-transform: uppercase; letter-spacing: 0.3px; margin-right: 4px; }
.uc-kpi-rf__opssig span { border-left: 3px solid var(--warn); background: #fdf6ee; padding: 2px 8px; }
.uc-kpi-rf__opssig span.lv-cao { border-left-color: var(--bad); background: #fdf3f3; }
.uc-kpi-rf__opscards { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 6px; }
.uc-kpi-rf__opscard { border: 1px dashed #c8c6c4; background: #faf9f8; padding: 6px 8px; cursor: pointer; display: flex; flex-direction: column; gap: 2px; min-width: 0; }
.uc-kpi-rf__opscard:hover { border-color: #1B365D; border-style: solid; background: #fff; }
.uc-kpi-rf__opscard .oc-h { display: flex; justify-content: space-between; align-items: center; }
.uc-kpi-rf__opscard .oc-code { font-size: 10.5px; font-weight: 700; color: var(--ink2); }
.uc-kpi-rf__opscard .uc-kpi-rf__hb { margin-right: 0; }
.uc-kpi-rf__opscard .oc-n { font-weight: 600; font-size: 12px; line-height: 1.3; min-height: 31px; }
.uc-kpi-rf__opscard .oc-v { font-size: 18px; font-weight: 600; color: #a19f9d; }
.uc-kpi-rf__opscard .oc-v small { font-size: 10.5px; font-weight: 400; font-style: italic; margin-left: 6px; }
.uc-kpi-rf__opscard .oc-t { font-size: 11px; color: var(--ink2); }
.uc-kpi-rf__opscard .oc-t b { color: var(--ink); }
.uc-kpi-rf__opscard .oc-m, .uc-kpi-rf__opscard .oc-o { font-size: 10.5px; color: var(--ink3); }
@media (max-width: 900px) {
  .uc-kpi-rf__dictd { position: static; }
  .uc-kpi-rf__dictflow { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
.uc-kpi-rf__nar { float: right; font-style: normal; font-size: 10px; font-weight: 600; text-transform: none; letter-spacing: 0; background: rgba(255, 255, 255, 0.14); border: 1px solid rgba(255, 255, 255, 0.35); padding: 0 6px; margin-left: 8px; cursor: help; opacity: 1; }
.uc-kpi-rf__nar.is-inline { float: none; display: inline-block; background: #fff; color: #8a5a00; border-color: #e5c27a; margin: 0 8px 0 -2px; vertical-align: 2px; }
.uc-kpi-rf__anbar { margin: 8px 14px 0; padding: 5px 10px; background: #fdf6ee; border: 1px solid #f0c493; border-left: 3px solid var(--warn); font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__anbar b { color: #8a5a00; margin-right: 6px; text-transform: uppercase; font-size: 11px; letter-spacing: 0.3px; }
.uc-kpi-rf__tabs { align-items: stretch; }
.uc-kpi-rf__tabgrp { display: flex; align-items: stretch; flex-shrink: 0; }
.uc-kpi-rf__tabs .tb-s { display: none; }
.uc-kpi-rf__tabgrp + .uc-kpi-rf__tabgrp { border-left: 1px solid var(--line); margin-left: 6px; padding-left: 6px; }
.uc-kpi-rf__tabgrp-l { align-self: center; font-size: 9.5px; font-weight: 700; text-transform: uppercase; letter-spacing: 0.4px; color: var(--ink3); padding: 0 6px 0 2px; white-space: nowrap; }
.uc-kpi-rf__tabgrp.is-pt { background: #fdf6ee; }
.uc-kpi-rf__tabgrp.is-pt .uc-kpi-rf__tabgrp-l { color: #8a5a00; }
@media (max-width: 1400px) {
  .uc-kpi-rf { padding-bottom: 72px; }
  .uc-kpi-rf__tabs { flex-direction: column; overflow-x: visible; padding: 0; }
  .uc-kpi-rf__tabgrp { overflow-x: auto; padding: 0 8px; }
  .uc-kpi-rf__tabgrp + .uc-kpi-rf__tabgrp { border-left: 0; margin-left: 0; padding-left: 8px; border-top: 1px solid var(--line); }
  .uc-kpi-rf__tabgrp-l { width: 150px; flex-shrink: 0; }
  .uc-kpi-rf__tabs button { padding: 6px 10px; }
}
@media (max-width: 900px) {
  .uc-kpi-rf__tabgrp-l { display: none; }
  .uc-kpi-rf__tabs .tb-l { display: none; }
  .uc-kpi-rf__tabs .tb-s { display: inline; }
  .uc-kpi-rf__tabgrp, .uc-kpi-rf__tabgrp + .uc-kpi-rf__tabgrp { padding: 0 2px; }
  .uc-kpi-rf__tabs button { padding: 6px 8px; font-size: 11.5px; }
}
@media (max-width: 900px) { .uc-kpi-rf__nar { float: none; display: inline-block; margin: 2px 0 0 0; } }
/* Results Framework page */
.uc-kpi-rf { --ks-good: #1a9e4b; --ks-good-t: #e7f4ec; --ks-part: #3A6EA5; --ks-part-t: #e8eef5; --ks-prep: #5C6B7A; --ks-prep-t: #eef0f2;
  --ks-warn: #d9822b; --ks-warn-t: #fdf1e3; --ks-bad: #d13438; --ks-bad-t: #fbe9ea; --ks-none: #8a8886; --ks-none-t: #f3f2f1; }
.uc-kpi-rf__rfblock { margin-bottom: 10px; }
.uc-kpi-rf__rflegend { display: flex; flex-wrap: wrap; gap: 4px 12px; font-size: 11.5px; color: var(--ink2); }
.uc-kpi-rf__rflegend i { display: inline-block; width: 10px; height: 10px; margin-right: 4px; vertical-align: -1px; }
.uc-kpi-rf__sks { display: grid; grid-template-columns: repeat(7, minmax(0, 1fr)); gap: 8px; }
.uc-kpi-rf__sk { display: flex; flex-direction: column; gap: 4px; text-align: left; font: inherit; cursor: pointer; border: 1px solid transparent; border-top: 4px solid; padding: 8px 10px; min-width: 0; }
.uc-kpi-rf__sk:hover { border-color: var(--accent2); border-top-width: 4px; }
.uc-kpi-rf__sk .sk-h { display: flex; justify-content: space-between; align-items: baseline; gap: 4px; }
.uc-kpi-rf__sk .sk-h b { font-size: 15px; color: var(--accent2); }
.uc-kpi-rf__sk .sk-h em { font-style: normal; font-size: 10.5px; font-weight: 700; text-align: right; }
.uc-kpi-rf__sk .sk-n { font-size: 13px; font-weight: 600; color: var(--ink); line-height: 1.3; min-height: 34px; }
.uc-kpi-rf__sk .sk-b { display: grid; grid-template-columns: 1fr auto; gap: 6px; align-items: center; }
.uc-kpi-rf__sk .sk-b small { font-size: 10.5px; color: var(--ink2); }
.uc-kpi-rf__sk .sk-c { font-size: 10.5px; color: var(--ink3); }
.uc-kpi-rf__chain { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; }
.uc-kpi-rf__cg { min-width: 0; background: #faf9f8; border: 1px solid var(--line); }
.uc-kpi-rf__cg-h { display: grid; grid-template-columns: auto 1fr; gap: 10px; align-items: center; background: var(--accent2); color: #fff; padding: 10px 12px; }
.uc-kpi-rf__cg-h .cg-n { font-family: Georgia, serif; font-size: 30px; line-height: 1; color: #C3CFDC; }
.uc-kpi-rf__cg-h .cg-t { font-size: 12.5px; font-weight: 600; line-height: 1.35; display: -webkit-box; -webkit-line-clamp: 3; -webkit-box-orient: vertical; overflow: hidden; }
.uc-kpi-rf__cg-m { font-size: 11px; color: var(--ink2); padding: 5px 12px; border-bottom: 1px solid var(--line); background: #EEF2F6; }
.uc-kpi-rf__co { margin: 8px; background: #fff; border: 1px solid var(--line); border-left: 3px solid var(--accent); padding: 7px 9px; }
.uc-kpi-rf__co-h { display: grid; grid-template-columns: auto 1fr; gap: 6px; font-size: 12px; font-weight: 600; line-height: 1.35; margin-bottom: 4px; }
.uc-kpi-rf__co-h b { color: var(--accent); }
.uc-kpi-rf__co-h span { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.uc-kpi-rf__kr { display: grid; grid-template-columns: 8px auto 1fr auto; gap: 7px; align-items: center; width: 100%; text-align: left; font: inherit; cursor: pointer; border: 0; padding: 6px 8px; margin-top: 4px; }
.uc-kpi-rf__kr:hover { outline: 1px solid var(--accent2); }
.uc-kpi-rf__kr i { width: 8px; height: 8px; border-radius: 50%; }
.uc-kpi-rf__kr b { font-size: 11.5px; color: var(--accent2); }
.uc-kpi-rf__kr span { font-size: 12.5px; font-weight: 600; color: var(--ink); line-height: 1.3; }
.uc-kpi-rf__kr em { font-style: normal; font-size: 10.5px; font-weight: 700; white-space: nowrap; }
.uc-kpi-rf__sk.ks-good, .uc-kpi-rf__kr.ks-good { background: var(--ks-good-t); border-top-color: var(--ks-good); }
.uc-kpi-rf__sk.ks-part, .uc-kpi-rf__kr.ks-part { background: var(--ks-part-t); border-top-color: var(--ks-part); }
.uc-kpi-rf__sk.ks-prep, .uc-kpi-rf__kr.ks-prep { background: var(--ks-prep-t); border-top-color: var(--ks-prep); }
.uc-kpi-rf__sk.ks-warn, .uc-kpi-rf__kr.ks-warn { background: var(--ks-warn-t); border-top-color: var(--ks-warn); }
.uc-kpi-rf__sk.ks-bad, .uc-kpi-rf__kr.ks-bad { background: var(--ks-bad-t); border-top-color: var(--ks-bad); }
.uc-kpi-rf__sk.ks-none, .uc-kpi-rf__kr.ks-none { background: var(--ks-none-t); border-top-color: var(--ks-none); }
.uc-kpi-rf__kr { border-top: 0 !important; }
.ks-good em, .ks-good > i, .uc-kpi-rf__rflegend .ks-good i { color: var(--ks-good); background-color: var(--ks-good); }
.ks-part em, .ks-part > i, .uc-kpi-rf__rflegend .ks-part i { color: var(--ks-part); background-color: var(--ks-part); }
.ks-prep em, .ks-prep > i, .uc-kpi-rf__rflegend .ks-prep i { color: var(--ks-prep); background-color: var(--ks-prep); }
.ks-warn em, .ks-warn > i, .uc-kpi-rf__rflegend .ks-warn i { color: var(--ks-warn); background-color: var(--ks-warn); }
.ks-bad em, .ks-bad > i, .uc-kpi-rf__rflegend .ks-bad i { color: var(--ks-bad); background-color: var(--ks-bad); }
.ks-none em, .ks-none > i, .uc-kpi-rf__rflegend .ks-none i { color: var(--ks-none); background-color: var(--ks-none); }
.uc-kpi-rf__sk em, .uc-kpi-rf__kr em { background-color: transparent !important; }
.uc-kpi-rf__sk .sk-h em { background: none; }
@media (max-width: 1300px) { .uc-kpi-rf__sks { grid-template-columns: repeat(4, minmax(0, 1fr)); } }
@media (max-width: 1100px) { .uc-kpi-rf__chain { grid-template-columns: 1fr; } }
@media (max-width: 700px) { .uc-kpi-rf__sks { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
/* standard KPI tile: trend + comparison */
.uc-kpi-rf__bkpi-h { display: flex; justify-content: space-between; align-items: baseline; gap: 6px; font-size: 13px; font-weight: 600; color: var(--ink2); }
.uc-kpi-rf__bkpi-h b { font-size: 12px; white-space: nowrap; }
.uc-kpi-rf__bkpi.is-good .uc-kpi-rf__bkpi-h b { color: var(--good); }
.uc-kpi-rf__bkpi.is-warn .uc-kpi-rf__bkpi-h b { color: var(--warn); }
.uc-kpi-rf__bkpi.is-bad .uc-kpi-rf__bkpi-h b { color: var(--bad); }
.uc-kpi-rf__bkpi.is-none { border-top-color: #5C6B7A; cursor: default; }
.uc-kpi-rf__bkpi.is-click { cursor: pointer; }
.uc-kpi-rf__bkpi-m { display: flex; align-items: flex-end; justify-content: space-between; gap: 8px; }
.uc-kpi-rf__bkpi-m .uc-kpi-rf__bkpi-v { font-size: 30px; white-space: nowrap; }
.uc-kpi-rf__spark { width: 120px; height: 46px; flex: none; overflow: visible; }
.uc-kpi-rf__spark .sp-l { fill: none; stroke: var(--accent); stroke-width: 2; }
.uc-kpi-rf__spark .sp-d { fill: #fff; stroke: var(--accent); stroke-width: 1.5; }
.uc-kpi-rf__spark .sp-d.is-last { fill: var(--accent2); stroke: var(--accent2); }
.uc-kpi-rf__spark .sp-tg { stroke: #8a8886; stroke-width: 1; stroke-dasharray: 3 3; }
.uc-kpi-rf__spark .sp-x { font-size: 10px; fill: var(--ink3); }
.uc-kpi-rf__bkpi-d { font-size: 12px; color: var(--ink2); margin: 2px 0 6px; flex: none; }
.uc-kpi-rf__cmp { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); border-top: 1px solid var(--line); padding-top: 6px; margin-top: auto; }
.uc-kpi-rf__cmp span { display: flex; flex-direction: column; min-width: 0; padding-right: 4px; }
.uc-kpi-rf__cmp span + span { border-left: 1px solid #f3f2f1; padding-left: 6px; }
.uc-kpi-rf__cmp i { font-style: normal; font-size: 11px; color: var(--ink3); white-space: nowrap; }
.uc-kpi-rf__cmp b { font-size: 12.5px; font-weight: 600; color: var(--ink); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__cmp .is-good b { color: var(--good); }
.uc-kpi-rf__cmp .is-bad b { color: var(--bad); }
.uc-kpi-rf__cmp .is-py b { color: var(--ink2); font-weight: 400; }
.uc-kpi-rf__cmpnote { margin: -4px 0 8px; }
/* coverage matrix */
.uc-kpi-rf__covsum { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-bottom: 10px; }
.uc-kpi-rf__covg { background: var(--card); border: 1px solid var(--line); padding: 10px 12px; }
.uc-kpi-rf__covg .cv-h { display: flex; justify-content: space-between; gap: 6px; font-size: 13px; margin-bottom: 6px; }
.uc-kpi-rf__covg .cv-h b { color: var(--accent2); }
.uc-kpi-rf__covg .cv-h span { color: var(--ink2); white-space: nowrap; }
.uc-kpi-rf__covg .cv-bar { display: flex; height: 10px; background: #edebe9; }
.uc-kpi-rf__covg .cv-bar i, .uc-kpi-rf__covg .cv-l i { display: block; }
.uc-kpi-rf__covg i.is-good { background: var(--accent2); }
.uc-kpi-rf__covg i.is-part { background: #8FA9C6; }
.uc-kpi-rf__covg .cv-l { display: flex; flex-wrap: wrap; gap: 4px 10px; margin-top: 6px; font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__covg .cv-l i { display: inline-block; width: 10px; height: 10px; background: #edebe9; margin-right: 4px; vertical-align: -1px; }
.uc-kpi-rf__covt td { font-size: 12.5px; }
.uc-kpi-rf__covt tr.is-grp td { background: #EEF2F6; color: var(--accent2); font-size: 12.5px; }
.uc-kpi-rf__covsig { margin-left: 10px; font-size: 12px; color: var(--warn); font-weight: 600; }
.uc-kpi-rf__covsig.lv-cao { color: var(--bad); }
.uc-kpi-rf__cov { display: inline-block; padding: 1px 8px; font-size: 12px; font-weight: 600; border: 1px solid; white-space: nowrap; }
.uc-kpi-rf__cov.is-good { color: #fff; background: var(--accent2); border-color: var(--accent2); }
.uc-kpi-rf__cov.is-part { color: var(--accent2); background: #E3EAF2; border-color: #8FA9C6; }
.uc-kpi-rf__cov.is-none { color: var(--ink3); background: #fff; border-color: #c8c6c4; border-style: dashed; }
/* presentation mode */
.uc-kpi-rf__tabrow.is-present { align-items: center; gap: 2px; }
.uc-kpi-rf__tabrow.is-present button { font-size: 13.5px; padding: 10px 14px; }
.uc-kpi-rf__tabrow.is-present .is-exit { margin-left: auto; color: var(--ink3); }
@media (max-width: 1100px) { .uc-kpi-rf__covsum { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 900px) { .uc-kpi-rf__bkpi-m .uc-kpi-rf__bkpi-v { font-size: 26px; } }
/* board page: chair-level summary */
.uc-kpi-rf__bkpi-i { font-size: 11px; color: var(--accent); margin-top: 4px; }
.uc-kpi-rf__bkpi:hover .uc-kpi-rf__bkpi-i { text-decoration: underline; }
.uc-kpi-rf__bimp { margin-left: 8px; border: 0; background: none; padding: 0; color: var(--accent); font: inherit; font-size: 11px; cursor: pointer; }
.uc-kpi-rf__bhead { background: var(--accent2); color: #fff; padding: 16px 20px; margin-bottom: 10px; }
.uc-kpi-rf__bhead-k { font-size: 11px; letter-spacing: 0.6px; text-transform: uppercase; color: #C3CFDC; }
.uc-kpi-rf__bhead-t { font-family: Georgia, 'Times New Roman', serif; font-size: 21px; line-height: 1.4; margin: 6px 0 6px; max-width: 1100px; }
.uc-kpi-rf__bhead-s { font-size: 11.5px; color: #C3CFDC; }
.uc-kpi-rf__bkpis { display: grid; grid-template-columns: repeat(4, minmax(0, 1fr)); gap: 10px; margin-bottom: 10px; }
.uc-kpi-rf__bkpi { background: var(--card); border: 1px solid var(--line); border-top: 4px solid #a19f9d; padding: 12px 14px 10px; cursor: pointer; display: flex; flex-direction: column; }
.uc-kpi-rf__bkpi:hover { border-color: var(--accent2); }
.uc-kpi-rf__bkpi.is-good { border-top-color: var(--good); }
.uc-kpi-rf__bkpi.is-warn { border-top-color: var(--warn); }
.uc-kpi-rf__bkpi.is-bad { border-top-color: var(--bad); }
.uc-kpi-rf__bkpi-k { font-size: 12px; font-weight: 600; color: var(--ink2); }
.uc-kpi-rf__bkpi-v { font-size: 34px; font-weight: 600; color: var(--accent2); line-height: 1.15; margin: 4px 0 2px; font-variant-numeric: tabular-nums; }
.uc-kpi-rf__bkpi-d { font-size: 12px; color: var(--ink2); flex: 1; }
.uc-kpi-rf__bkpi-f { display: flex; justify-content: space-between; gap: 6px; border-top: 1px solid var(--line); margin-top: 8px; padding-top: 6px; font-size: 11.5px; color: var(--ink3); }
.uc-kpi-rf__bkpi.is-good .uc-kpi-rf__bkpi-f b { color: var(--good); }
.uc-kpi-rf__bkpi.is-warn .uc-kpi-rf__bkpi-f b { color: var(--warn); }
.uc-kpi-rf__bkpi.is-bad .uc-kpi-rf__bkpi-f b { color: var(--bad); }
.uc-kpi-rf__bcols { display: grid; grid-template-columns: minmax(0, 1fr) minmax(0, 1fr); gap: 10px; margin-bottom: 10px; }
.uc-kpi-rf__bbox { background: var(--card); border: 1px solid var(--line); padding: 12px 16px; }
.uc-kpi-rf__bbox-h { font-size: 13px; font-weight: 700; color: var(--accent2); text-transform: uppercase; letter-spacing: 0.4px; border-bottom: 2px solid var(--accent2); padding-bottom: 6px; margin-bottom: 4px; }
.uc-kpi-rf__bbox-h span { float: right; font-weight: 600; color: var(--ink3); }
.uc-kpi-rf__bitem { display: grid; grid-template-columns: 22px minmax(0, 1fr); gap: 8px; padding: 8px 0; border-bottom: 1px solid #f3f2f1; }
.uc-kpi-rf__bitem:last-child { border-bottom: 0; }
.uc-kpi-rf__bitem-n { font-family: Georgia, serif; font-size: 18px; color: var(--accent); line-height: 1.1; }
.uc-kpi-rf__bitem-t { font-size: 13.5px; font-weight: 600; color: var(--ink); line-height: 1.35; }
.uc-kpi-rf__bitem-d { font-size: 12px; color: var(--ink2); line-height: 1.4; margin-top: 2px; display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; }
.uc-kpi-rf__bitem-o { font-size: 11px; color: var(--ink3); margin-top: 2px; }
.uc-kpi-rf__bbox.is-dec .uc-kpi-rf__bitem-n { color: var(--accent2); }
.uc-kpi-rf__bstrip { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 10px; margin-bottom: 8px; }
.uc-kpi-rf__bstrip button { display: grid; grid-template-columns: 1fr auto; align-items: center; gap: 2px 10px; text-align: left; background: #faf9f8; border: 1px solid var(--line); padding: 8px 12px; cursor: pointer; font: inherit; color: var(--ink); }
.uc-kpi-rf__bstrip button:hover { border-color: var(--accent2); }
.uc-kpi-rf__bstrip .bs-k { font-size: 12px; color: var(--ink2); }
.uc-kpi-rf__bstrip .bs-v { grid-row: 1 / 3; grid-column: 2; font-size: 22px; font-weight: 600; color: var(--accent2); }
.uc-kpi-rf__bstrip .bs-v small { font-size: 12px; color: var(--ink3); font-weight: 400; }
.uc-kpi-rf__bstrip .bs-n { font-size: 11px; color: var(--ink3); white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.uc-kpi-rf__bstrip .bs-bar { height: 6px; margin: 0; }
.uc-kpi-rf__bmore { display: block; width: 100%; background: transparent; border: 1px dashed #C3CFDC; color: var(--accent2); font: inherit; font-size: 12px; padding: 7px; cursor: pointer; margin-bottom: 8px; }
@media (max-width: 1100px) { .uc-kpi-rf__bkpis { grid-template-columns: repeat(2, minmax(0, 1fr)); } }
@media (max-width: 900px) {
  .uc-kpi-rf__bcols, .uc-kpi-rf__bstrip { grid-template-columns: 1fr; }
  .uc-kpi-rf__bhead-t { font-size: 18px; }
}
/* 4 tiers + strategic KPI dictionary */
.uc-kpi-rf { padding-bottom: 76px; }
.uc-kpi-rf__tabs { flex-direction: column; overflow-x: visible; padding: 0; }
.uc-kpi-rf__tabrow { display: flex; align-items: stretch; overflow-x: auto; padding: 0 8px; }
.uc-kpi-rf__tabrow + .uc-kpi-rf__tabrow { border-top: 1px solid var(--line); }
.uc-kpi-rf__tabrow .uc-kpi-rf__tabgrp { padding: 0; overflow: visible; }
.uc-kpi-rf__tabrow .uc-kpi-rf__tabgrp + .uc-kpi-rf__tabgrp { border-top: 0; border-left: 1px solid var(--line); margin-left: 6px; padding-left: 6px; }
.uc-kpi-rf__tabrow .uc-kpi-rf__tabgrp-l { width: auto; padding: 0 8px 0 2px; }
.uc-kpi-rf__tabgrp.is-A .uc-kpi-rf__tabgrp-l, .uc-kpi-rf__tabgrp.is-D .uc-kpi-rf__tabgrp-l { color: #1B365D; }
.uc-kpi-rf__tabgrp.is-B, .uc-kpi-rf__tabgrp.is-C { background: #faf9f8; }
.uc-kpi-rf__tabs button.is-later { color: var(--ink3); font-style: italic; }
.uc-kpi-rf__tabs button { padding: 6px 10px; }
@media (max-width: 1400px) {
  .uc-kpi-rf__tabs .tb-l { display: none; }
  .uc-kpi-rf__tabs .tb-s { display: inline; }
}
@media (max-width: 900px) {
  .uc-kpi-rf__tabrow { padding: 0 2px; }
  .uc-kpi-rf__tabrow .uc-kpi-rf__tabgrp + .uc-kpi-rf__tabgrp { margin-left: 2px; padding-left: 2px; }
}
.uc-kpi-rf__tierbar { justify-content: flex-start; }
.uc-kpi-rf__tiernote { font-size: 11px; color: var(--ink3); }
.uc-kpi-rf__rftable td:nth-child(4) { white-space: normal; }
.uc-kpi-rf__owner { display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden; max-width: 220px; white-space: normal; }
.uc-kpi-rf__minibar { position: relative; height: 6px; background: #edebe9; min-width: 60px; }
.uc-kpi-rf__minibar i { position: absolute; left: 0; top: 0; bottom: 0; background: #3A6EA5; }
.uc-kpi-rf__rfd { max-height: calc(100vh - 110px); overflow-y: auto; }
.uc-kpi-rf__rfsec { margin-bottom: 10px; }
.uc-kpi-rf__rfsec h4 { margin: 0 0 4px; font-size: 11px; text-transform: uppercase; letter-spacing: 0.3px; color: #1B365D; border-bottom: 1px solid #C3CFDC; padding-bottom: 2px; }
.uc-kpi-rf__rfpts { width: 100%; border-collapse: collapse; margin-top: 6px; font-size: 11.5px; }
.uc-kpi-rf__rfpts td { padding: 3px 4px; border-bottom: 1px solid #f3f2f1; vertical-align: top; }
.uc-kpi-rf__rfpts td:first-child { color: var(--ink3); white-space: nowrap; width: 38px; }
.uc-kpi-rf__rfpts small { display: block; color: var(--ink2); font-size: 11px; }
.uc-kpi-rf__rflinks { display: flex; flex-wrap: wrap; gap: 4px; }
.uc-kpi-rf__rflinks button, .uc-kpi-rf__rflink1 { border: 1px solid #C3CFDC; background: #EEF2F6; color: #1B365D; font-size: 11.5px; padding: 2px 8px; cursor: pointer; text-align: left; }
.uc-kpi-rf__rfbase { display: grid; grid-template-columns: 1fr 90px 40px; gap: 6px; align-items: center; font-size: 11.5px; padding: 2px 0; }
.uc-kpi-rf__rfbase small { grid-column: 1 / -1; color: var(--warn); font-style: italic; font-size: 10.5px; margin-top: -2px; }
.uc-kpi-rf__rfreview { border-left: 3px solid var(--warn); background: #fdf6ee; padding: 6px 10px; font-size: 12px; }
.uc-kpi-rf__rfreview ul { margin: 4px 0 0; padding-left: 16px; }
.uc-kpi-rf__rfsys { display: flex; flex-wrap: wrap; gap: 6px; align-items: stretch; margin-bottom: 8px; }
.uc-kpi-rf__rfsys-l { align-self: center; font-size: 11px; font-weight: 700; text-transform: uppercase; color: var(--ink2); margin-right: 4px; }
.uc-kpi-rf__kchip { display: flex; flex-direction: column; align-items: flex-start; text-align: left; border: 1px solid var(--line); border-left: 3px solid #a19f9d; background: #fff; padding: 4px 8px; cursor: pointer; max-width: 260px; min-width: 150px; margin: 4px 4px 0 0; }
.uc-kpi-rf__kchip:hover { border-color: #1B365D; }
.uc-kpi-rf__kchip b { font-size: 11px; color: #1B365D; }
.uc-kpi-rf__kchip span { font-size: 11.5px; line-height: 1.3; color: var(--ink); }
.uc-kpi-rf__kchip small { font-size: 10px; color: var(--ink3); margin-top: 1px; }
.uc-kpi-rf__kchip.ks-good { border-left-color: var(--good); }
.uc-kpi-rf__kchip.ks-part { border-left-color: #3A6EA5; }
.uc-kpi-rf__kchip.ks-prep { border-left-color: #5C6B7A; }
.uc-kpi-rf__kchip.ks-warn { border-left-color: var(--warn); }
.uc-kpi-rf__kchip.ks-bad { border-left-color: var(--bad); }
.uc-kpi-rf__rfgoals { display: grid; grid-template-columns: repeat(3, minmax(0, 1fr)); gap: 8px; }
.uc-kpi-rf__rfgoal { border: 1px solid var(--line); background: #faf9f8; padding: 6px 8px; min-width: 0; }
.uc-kpi-rf__rfgoal-h b { display: block; font-size: 11px; text-transform: uppercase; color: #1B365D; }
.uc-kpi-rf__rfgoal-h span { display: block; font-size: 12px; font-weight: 600; line-height: 1.35; margin-bottom: 4px; }
.uc-kpi-rf__rfout { background: #fff; border: 1px solid var(--line); padding: 5px 7px; margin-top: 6px; }
.uc-kpi-rf__rfout-h { font-size: 12px; font-weight: 600; line-height: 1.35; }
.uc-kpi-rf__rfout-h b { color: #1B365D; margin-right: 4px; }
.uc-kpi-rf__rfact { margin: 3px 0 2px; padding-left: 0; list-style: none; font-size: 11px; color: var(--ink2); }
.uc-kpi-rf__rfact li { line-height: 1.35; padding: 1px 0; }
.uc-kpi-rf__rfact i { font-style: normal; color: var(--ink3); margin-right: 3px; }
.uc-kpi-rf__rfbasegrid { display: grid; grid-template-columns: repeat(auto-fill, minmax(190px, 1fr)); gap: 6px; }
.uc-kpi-rf__rfbasecard { border: 1px solid var(--line); padding: 5px 7px; cursor: pointer; background: #fff; }
.uc-kpi-rf__rfbasecard:hover { border-color: #1B365D; }
.uc-kpi-rf__rfbasecard .bh { display: flex; justify-content: space-between; font-size: 12px; margin-bottom: 3px; }
.uc-kpi-rf__rfbasecard .bh span { font-weight: 700; color: #1B365D; }
.uc-kpi-rf__rfbasecard .br { display: grid; grid-template-columns: 1fr 70px; gap: 6px; align-items: center; font-size: 10.5px; color: var(--ink2); }
.uc-kpi-rf__rfbasecard .br span { overflow: hidden; text-overflow: ellipsis; white-space: nowrap; }
.uc-kpi-rf__rfbasecard .br em { grid-column: 1 / -1; color: var(--warn); font-size: 10px; margin-top: -2px; }
.uc-kpi-rf__cutbox { margin-bottom: 6px; }
.uc-kpi-rf__cutbox td small { display: block; }
.uc-kpi-rf__cutnext { display: flex; flex-wrap: wrap; gap: 4px 8px; align-items: center; margin-top: 6px; font-size: 11.5px; }
.uc-kpi-rf__cutnext b { font-size: 11px; color: var(--ink2); text-transform: uppercase; margin-right: 4px; }
.uc-kpi-rf__cutnext .uc-kpi-rf__cutd { display: inline-flex; flex-wrap: wrap; align-items: center; gap: 3px; margin-right: 8px; }
.uc-kpi-rf__cutd em { font-style: normal; font-weight: 600; color: var(--ink); margin-right: 2px; }
.uc-kpi-rf__cutd button { border: 1px solid #C3CFDC; background: #EEF2F6; color: #1B365D; padding: 0 6px; font-size: 11px; cursor: pointer; }
.uc-kpi-rf__tierlist { margin: 0; padding-left: 18px; font-size: 12.5px; line-height: 1.6; }
.uc-kpi-rf__tierlist.is-pre li::marker { color: var(--bad); }
@media (max-width: 1100px) { .uc-kpi-rf__rfgoals { grid-template-columns: 1fr; } }
@media (max-width: 900px) { .uc-kpi-rf__rfd { max-height: none; } }
/* compact pages: same density as the spotlight (iPad-first) */
.uc-kpi-rf { font-size: 12.5px; padding-bottom: 44px; }
.uc-kpi-rf__top { padding: 8px 14px; }
.uc-kpi-rf__title { font-size: 16px; }
.uc-kpi-rf__subtitle { font-size: 12px; margin-top: 0; }
.uc-kpi-rf__slicers { padding: 6px 14px; gap: 16px; }
.uc-kpi-rf__slicer-label { margin-bottom: 2px; }
.uc-kpi-rf__seg button { padding: 3px 10px; }
.uc-kpi-rf__page { padding: 8px 14px 0; }
.uc-kpi-rf__lead { padding: 8px 12px; margin-bottom: 6px; }
.uc-kpi-rf__lead-t { font-size: 13px; line-height: 1.5; margin-top: 2px; }
.uc-kpi-rf__stats { gap: 6px; margin-bottom: 6px; }
.uc-kpi-rf__stat { padding: 6px 10px; }
.uc-kpi-rf__stat-k { font-size: 11px; }
.uc-kpi-rf__stat-v { font-size: 18px; margin-top: 2px; }
.uc-kpi-rf__stat-v small { font-size: 11px; }
.uc-kpi-rf__stat-d { font-size: 10.5px; margin-top: 1px; }
.uc-kpi-rf__grid { gap: 6px; }
.uc-kpi-rf__visual { padding: 8px 10px; }
.uc-kpi-rf__vhead { margin-bottom: 6px; }
.uc-kpi-rf__vtitle { font-size: 13px; }
.uc-kpi-rf__src { padding-top: 6px; }
.uc-kpi-rf__callout { padding: 6px 8px; margin-top: 6px; line-height: 1.45; }
.uc-kpi-rf__table th { padding: 4px 6px; }
.uc-kpi-rf__table td { padding: 4px 6px; }
.uc-kpi-rf__risk { padding: 5px 0; gap: 8px; }
.uc-kpi-rf__risk-d { font-size: 11.5px; }
.uc-kpi-rf__kpimini-row { padding: 3px 0; }
.uc-kpi-rf__trust b { font-size: 18px; }
.uc-kpi-rf__trust div { padding: 6px 8px; }
.uc-kpi-rf__decision { padding: 4px 0; }
.uc-kpi-rf__decision-e { font-size: 11.5px; }
.uc-kpi-rf__hbars { gap: 5px; }
.uc-kpi-rf__funits { gap: 8px; }
.uc-kpi-rf__funit-h { font-size: 12.5px; }
.uc-kpi-rf__assume div { padding: 3px 0; }
.uc-kpi-rf__tabs { padding: 0 8px; }
.uc-kpi-rf__tabs button { padding: 7px 12px; font-size: 12px; }
.uc-kpi-rf__simbtn { padding: 4px 10px; }
.uc-kpi-rf__simbar { padding: 6px 10px; gap: 12px; margin-bottom: 6px; }
.uc-kpi-rf__gv { gap: 6px; margin-bottom: 6px; }
.uc-kpi-rf__gv-group { padding: 6px 8px; }
.uc-kpi-rf__gv-c { padding: 3px 6px; }
.uc-kpi-rf__gv-c b { font-size: 15px; }
.uc-kpi-rf__goal-row, .uc-kpi-rf__goal-need { padding: 4px 0; }
.uc-kpi-rf__qc-verdict { font-size: 16px; }
.uc-kpi-rf__dr-head { padding: 8px 14px; }
.uc-kpi-rf__dr-title { font-size: 14px; }
.uc-kpi-rf__dr-body { padding: 8px 14px 14px; }
@media (max-width: 1280px) {
  .uc-kpi-rf__stats { grid-template-columns: repeat(6, minmax(0, 1fr)); }
  .uc-kpi-rf__stat-v { font-size: 16px; }
  .uc-kpi-rf__gv { grid-template-columns: 1fr 1fr; }
  .uc-kpi-rf__gv-group:first-child { grid-column: span 2; }
}
@media (max-width: 900px) {
  .uc-kpi-rf__gv { grid-template-columns: 1fr; }
  .uc-kpi-rf__gv-group:first-child { grid-column: auto; }
}
@media (max-width: 900px) {
  .uc-kpi-rf__stats { grid-template-columns: repeat(3, minmax(0, 1fr)); }
}
/* readability floor: body text 12px */
.uc-kpi-rf__pill2,
.uc-kpi-rf__slicer-label,
.uc-kpi-rf__seg--sm button,
.uc-kpi-rf__lead-k,
.uc-kpi-rf__stat-k,
.uc-kpi-rf__stat-d,
.uc-kpi-rf__vnote,
.uc-kpi-rf__src,
.uc-kpi-rf__table th,
.uc-kpi-rf__table td small,
.uc-kpi-rf__tag,
.uc-kpi-rf__fmt,
.uc-kpi-rf__lvl,
.uc-kpi-rf__risk-o,
.uc-kpi-rf__stack span,
.uc-kpi-rf__legend,
.uc-kpi-rf__code,
.uc-kpi-rf__trust span,
.uc-kpi-rf__funit-row span,
.uc-kpi-rf__funit-d,
.uc-kpi-rf__hint,
.uc-kpi-rf__dr-kicker,
.uc-kpi-rf__dr-h span,
.uc-kpi-rf__route span,
.uc-kpi-rf__dr-note,
.uc-kpi-rf__imp-l small,
.uc-kpi-rf__src-tag,
.uc-kpi-rf__dr-sum-k,
.uc-kpi-rf__dr-foot,
.uc-kpi-rf__drv-l small,
.uc-kpi-rf__drv-o,
.uc-kpi-rf__hint2,
.uc-kpi-rf__legend2,
.uc-kpi-rf__tbar-l i,
.uc-kpi-rf__tbar-v small,
.uc-kpi-rf__namebtn,
.uc-kpi-rf__gv-c span,
.uc-kpi-rf__gv-c b small,
.uc-kpi-rf__gv-c > small,
.uc-kpi-rf__lv th,
.uc-kpi-rf__goal-need span,
.uc-kpi-rf__costhint,
.uc-kpi-rf__sp-kicker,
.uc-kpi-rf__sp-f > label,
.uc-kpi-rf__sp-rail-note,
.uc-kpi-rf__sp-bl-k,
.uc-kpi-rf__sp-kpi-k i,
.uc-kpi-rf__sp-kpi-s,
.uc-kpi-rf__qc-in label,
.uc-kpi-rf__gaps,
.uc-kpi-rf__sp-opts button,
.uc-kpi-rf__sp-f .uc-kpi-rf__select,
.uc-kpi-rf__sp-kpi-k,
.uc-kpi-rf__sp-kpi-from,
.uc-kpi-rf__sp-kpi .uc-kpi-rf__src-tag,
.uc-kpi-rf__sp .uc-kpi-rf__legend2,
.uc-kpi-rf__sp .uc-kpi-rf__formula,
.uc-kpi-rf__sp .uc-kpi-rf__gaps,
.uc-kpi-rf__sp .uc-kpi-rf__vstrip-lg,
.uc-kpi-rf__sp .uc-kpi-rf__tbar-l,
.uc-kpi-rf__sp .uc-kpi-rf__tbar-v,
.uc-kpi-rf__sp .uc-kpi-rf__dr-note, .uc-kpi-rf__sp .uc-kpi-rf__dr-foot,
.uc-kpi-rf__mapev span,
.uc-kpi-rf__bmrank-l small, .uc-kpi-rf__bmrank-v small,
.uc-kpi-rf__bmkey,
.uc-kpi-rf__bmsrc,
.uc-kpi-rf__bmplan span,
.uc-kpi-rf__bmplan small,
.uc-kpi-rf__mode,
.uc-kpi-rf__dictadd,
.uc-kpi-rf__dl dt,
.uc-kpi-rf__nar,
.uc-kpi-rf__anbar b,
.uc-kpi-rf__tabs button,
.uc-kpi-rf__rflegend,
.uc-kpi-rf__sk .sk-h em,
.uc-kpi-rf__sk .sk-b small,
.uc-kpi-rf__sk .sk-c,
.uc-kpi-rf__cg-m,
.uc-kpi-rf__kr b,
.uc-kpi-rf__kr em,
.uc-kpi-rf__bkpi-i,
.uc-kpi-rf__bimp,
.uc-kpi-rf__bhead-k,
.uc-kpi-rf__bhead-s,
.uc-kpi-rf__bkpi-f,
.uc-kpi-rf__bitem-o,
.uc-kpi-rf__bstrip .bs-n,
.uc-kpi-rf__tiernote,
.uc-kpi-rf__rfsec h4,
.uc-kpi-rf__rfpts,
.uc-kpi-rf__rfpts small,
.uc-kpi-rf__rflinks button, .uc-kpi-rf__rflink1,
.uc-kpi-rf__rfbase,
.uc-kpi-rf__rfbase small,
.uc-kpi-rf__rfsys-l,
.uc-kpi-rf__rfgoal-h b,
.uc-kpi-rf__rfact,
.uc-kpi-rf__cutnext,
.uc-kpi-rf__cutnext b,
.uc-kpi-rf__cutd button,
.uc-kpi-rf__stat-v small,
.uc-kpi-rf__risk-d,
.uc-kpi-rf__decision-e { font-size: 12px; }
</style>
<template>
	<div class="mt-5 uc-decision-scope">
    <!-- Component top bar and table list -->
    <uc-main-view :decision-arr="decisionArr" :decision-filter="decisionFilter" :nganh-arr="nganhArr"
      :ds-nien-khoa="dsNienKhoa" @on-add="openAddModal" @on-detail="onDetailDecision" @on-edit="onEditData"
      @on-delete="handleDelete" @on-print-pdf="onPrintInTable" @on-print-word="onPrintWord" />

    <!-- Add Decision Dialog -->
    <uc-modal-add v-model="isAddModalOpen" :nganh-arr="nganhArr" :he-dao-tao="heDaoTao" @on-reload="getDecision" />

    <!-- Give SQD Dialog -->
    <uc-modal-give-sqd v-model="isDetailDialogOpen" :detail-decision="detailDecision" :detail-student="detailStudent"
      :file-list="fileList" @on-save="onUpdateSQD" />

    <!-- Edit Decision Dialog -->
    <uc-modal-edit v-model="isEditModalOpen" :detail-decision="detailDecision" :detail-student="detailStudent"
      :nganh-arr="nganhArr" @on-reload="getDecision" />
  </div>
</template>

<script>
	export default {
		name: "uc-main-page",
  data() {
    return {
      isAddModalOpen: false,
      isDetailDialogOpen: false,
      isEditModalOpen: false,

      decisionArr: [],
      decisionFilter: [],
      heDaoTao: [],
      nganhArr: [],
      dsNienKhoa: [],

      // Detail and edit data states
      detailDecision: {},
      detailStudent: [],
      fileList: [],
    };
  },
  mounted() {
    this.initData();
  },
  methods: {
    async initData() {
      await Promise.all([
        this.getDecision(),
        this.getHeDaoTao(),
        this.getNganhArr(),
        this.getNienKhoa(),
      ]);
    },

    async getDecision() {
      const resData = await ajaxCALLPromise("/Decision_Get_ByStatus", {
        Decision_Status: 0,
      });
      if (resData) {
        // Module decision chỉ dùng cho Thạc sĩ, loại bỏ các loại quyết định Tiến sĩ
        const PHD_DECISION_TYPES = ["QDBVCD1", "QDBVCD2", "QDBVCD3", "DGLATS", "NCS", "Tiến sĩ"];
        const thsData = resData.filter(
          (item) => !PHD_DECISION_TYPES.includes(item.Decision_Type)
        );

        // Sort: elements with DecisionFile_Url === null to the top
        const sortedData = thsData.sort((a, b) => {
          return (a.DecisionFile_Url === null ? -1 : 1) - (b.DecisionFile_Url === null ? -1 : 1);
        });
        
        // Re-assign stt
        this.decisionArr = sortedData.map((item, index) => {
          return {
            ...item,
            stt: index + 1,
          };
        });
        this.decisionFilter = [...this.decisionArr];
      }
    },

    async getHeDaoTao() {
      const resData = await ajaxCALLPromise("/hedaotao_get", null);
      if (resData) {
        // Chỉ lấy hệ Thạc sĩ
        this.heDaoTao = resData.filter((item) => item.KEY === "C");
      }
    },

    async getNganhArr() {
      try {
        this.nganhArr = await getNganhCaoHocPromise({ hasAllOption: true });
      } catch (error) {
        Vue.$toast.error(error.message || "Lỗi tải ngành học", { position: "top" });
      }
    },

    async getNienKhoa() {
      try {
        const res = await ajaxGETCALLPromise("https://tapi.lhu.edu.vn/hoso/Public_SelectNienKhoa");
        const defaultObj = {
          TenNienKhoa: "- Tất cả -",
          NienKhoa: "0",
        };

        const mappedNienKhoa = res.data.map((item) => {
          return {
            ...item,
            TenNienKhoa: item.NienKhoa,
            NienKhoa: item.NienKhoa,
          };
        });

        this.dsNienKhoa = [defaultObj, ...mappedNienKhoa];
      } catch (error) {
        Vue.$toast.error(error.message || "Lỗi tải niên khóa", { position: "top" });
      }
    },

    async getDecisionDetail(decisionID) {
      const resData = await ajaxCALLPromise("/Decision_Get_ByDecisionID", {
        Decision_ID: decisionID,
      });
      if (resData) {
        this.detailDecision = resData[0][0];
        this.detailStudent = resData[1].map((item, index) => {
          return {
            ...item,
            SoThuTu: index + 1,
          };
        });
        this.fileList = resData[2];
        return true;
      }
      return false;
    },

    async onDetailDecision(decisionID) {
      if (await this.getDecisionDetail(decisionID)) {
        this.isDetailDialogOpen = true;
      }
    },

    async onEditData(decisionID) {
      if (await this.getDecisionDetail(decisionID)) {
        this.isEditModalOpen = true;
      }
    },

    async onUpdateSQD(payload) {
      const resData = await ajaxCALLPromise("/Decision_Upd_SoQD", {
        Decision_ID: payload.Decision_ID,
        Decision_SoQD: payload.Decision_SoQD,
        Decision_NgayQD: payload.Decision_NgayQD,
        Decision_ThangQD: payload.Decision_ThangQD,
        Decision_NamQD: payload.Decision_NamQD,
        DecisionFile_ID: payload.DecisionFile_ID,
        DecisionFile_Url: payload.DecisionFile_Url,
        DecisionFile_Name: payload.DecisionFile_Name,
      });
      Vue.$toast.success("Cập nhật thành công", { position: "top" });
      this.isDetailDialogOpen = false;
      this.getDecision();
    },

    handleDelete(item) {
      confirm({
        title: "Bạn có xóa Số Quyết Định này?",
        action: async () => {
          await ajaxCALLPromise("/Decision_Del", {
            Decision_ID: item.Decision_ID,
          });
          Vue.$toast.success("Xóa thành công", { position: "top" });
          this.getDecision();
        },
      });
    },

    openAddModal() {
      this.isAddModalOpen = true;
    },

    // Print Logic
    htmlToPdf(decisionID, decisionType) {
      let url = "";
      if (decisionType === "Cao Học") {
        url = `https://qldetaisdh.lhu.edu.vn/rpt_dcsn_msthesis?Decision_ID=${decisionID}`;
      } else if (decisionType === "NCS") {
        url = `https://qldetaisdh.lhu.edu.vn/rpt_dcsn_phdthesis?Decision_ID=${decisionID}`;
      } else {
        Vue.$toast.error("Loại quyết định không hợp lệ", { position: "top" });
        return;
      }
      const newTab = window.open(url, "_blank");
      if (newTab) newTab.focus();
    },

    onPrintInTable(item) {
      this.htmlToPdf(item.Decision_ID, item.Decision_Type);
    },

    getMaNganh(nganhId) {
      const globalNganh = window.vueData?.NganhGlobal || [];
      const found = globalNganh.find((item) => item.NganhID == nganhId);
      return found ? found.MaNganh : "";
    },

    async onPrintWordetail(decisionID) {
      if (!decisionID) {
        Vue.$toast.error("Lỗi xảy ra: ID quyết định trống", { position: "top" });
        return;
      }

      const resData = await ajaxCALLPromise("/Decision_Get_ByDecisionID", {
        Decision_ID: decisionID,
      });

      if (!resData) return;

      const decisionDataQD = resData[0][0];
      const decisionDataDeTai = resData[1];

      const danhsachs = decisionDataDeTai
        .map((item) => {
          return {
            STT: item.STT,
            MSHV: item.Student_ID,
            Ho: item.Ho_SV,
            Ten: item.Ten_SV,
            HoVaTen: item.Ho_SV + " " + item.Ten_SV,
            NgaySinh: item.Ngay_Sinh,
            NoiSinh: item.Noi_Sinh,
            TenDeTai: item.Thesis_Name,
            GVHD1: item.Thesises_Prof1,
            GVHD2: item.Thesises_Prof2,
          };
        })
        .sort((a, b) => a.Ten.localeCompare(b.Ten));

      const model = {
        NganhInTable: decisionDataQD.Decision_Nganh,
        Khoa: decisionDataQD.Decision_NienKhoa
          ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
            (decisionDataQD.Decision_Dot === "" || decisionDataQD.Decision_Dot === null
              ? ""
              : "." + decisionDataQD.Decision_Dot)
          : "",
        So: decisionDataQD.Decision_MaSo,
        Ngay: decisionDataQD.Decision_NgayQD,
        Thang: decisionDataQD.Decision_ThangQD,
        Nam: decisionDataQD.Decision_NamQD,
        DanhSach: danhsachs.map((item, index) => {
          return {
            ...item,
            STT: (index + 1).toString(),
          };
        }),
      };

      const myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");

      const requestOptions = {
        method: "POST",
        headers: myHeaders,
        body: JSON.stringify(model),
        redirect: "follow",
      };

      const spaceChar = decisionDataQD.Decision_SoQD ? decisionDataQD.Decision_SoQD.charCodeAt(0) : 32;

      if (
        decisionDataQD.Decision_SoQD !== null &&
        decisionDataQD.Decision_NgayQD !== null &&
        decisionDataQD.Decision_ThangQD !== null &&
        decisionDataQD.Decision_NamQD !== null &&
        decisionDataQD.Decision_NienKhoa !== null &&
        decisionDataQD.Decision_Dot !== null &&
        decisionDataQD.Decision_Nganh !== null &&
        decisionDataQD.Decision_SLHVBangSo !== null &&
        decisionDataQD.Decision_SLHVBangChu !== null &&
        decisionDataQD.Decision_MaSo !== null &&
        decisionDataQD.Decision_NguoiTao !== null
      ) {
        if (decisionDataDeTai.length > 0) {
          const blob = await ajaxPOSTBlobPromise("https://gendocx.iotsoftvn.com/api/generate-docx/quyet-dinh-detail", model);
          if (blob) {
            const url = window.URL.createObjectURL(blob);
            const a = document.createElement("a");
            a.href = url;
            a.download = spaceChar === 32 ? "QuyetDinhGiaoDeTai.docx" : `${decisionDataQD.Decision_SoQD} QuyetDinhGiaoDeTai.docx`;
            document.body.appendChild(a);
            a.click();
            a.remove();
          }
        } else {
          Vue.$toast.error("Không có danh sách đề tài", { position: 'top' });
        }
      } else {
        Vue.$toast.error("Một số trường dữ liệu bị null", { position: 'top' });
      }
    },

    async onPrintWord(decisionID) {
      if (!decisionID) {
        Vue.$toast.error("Lỗi xảy ra: ID quyết định trống", { position: "top" });
        return;
      }

      const resData = await ajaxCALLPromise("/Decision_Get_ByDecisionID", {
        Decision_ID: decisionID,
      });

      if (!resData) return;

      const decisionDataQD = resData[0][0];
      const decisionDataDeTai = resData[1];

      const danhsachs = decisionDataDeTai
        .map((item) => ({
          STT: item.STT,
          MSHV: item.Student_ID,
          Ho: item.Ho_SV,
          Ten: item.Ten_SV,
          HoVaTen: item.Ho_SV + " " + item.Ten_SV,
          NgaySinh: item.Ngay_Sinh,
          NoiSinh: item.Noi_Sinh,
          TenDeTai: item.Thesis_Name,
          GVHD1: item.Thesises_Prof1,
          GVHD2: item.Thesises_Prof2,
          NoiCongTacGVHD1: item.CoQuanCongTac_GVHD1 ? item.CoQuanCongTac_GVHD1.trim() : "",
          NoiCongTacGVHD2: item.CoQuanCongTac_GVHD2 ? item.CoQuanCongTac_GVHD2.trim() : "",
          EmailGVHD1: item.Email_GVHD1 ? item.Email_GVHD1.trim() : "",
          EmailGVHD2: item.Email_GVHD2 ? item.Email_GVHD2.trim() : "",
          SoDienThoaiGVHD1: item.SoDT_GVHD1 ? item.SoDT_GVHD1.trim() : "",
          SoDienThoaiGVHD2: item.SoDT_GVHD2 ? item.SoDT_GVHD2.trim() : "",
        }))
        .sort((a, b) => a.Ten.localeCompare(b.Ten));

      const model = {
        SoQuyetDinh: decisionDataQD.Decision_SoQD,
        Ngay: decisionDataQD.Decision_NgayQD,
        Thang: decisionDataQD.Decision_ThangQD,
        Nam: decisionDataQD.Decision_NamQD,
        Nganh: decisionDataQD.Decision_Nganh,
        NganhID: decisionDataQD.Decision_NganhID ?? 0,
        MaNganh: this.getMaNganh(decisionDataQD.Decision_NganhID),
        ProcessID: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Process_ID : 0,
        Dot: decisionDataQD.Decision_Dot,
        Khoa: decisionDataQD.Decision_NienKhoa
          ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
            (decisionDataQD.Decision_Dot === "" || decisionDataQD.Decision_Dot === null
              ? ""
              : "." + decisionDataQD.Decision_Dot)
          : "",
        SoHocVien: danhsachs.length.toString(),
        SoHocVienBangChu: typeof numberToText === "function" ? numberToText(danhsachs.length) : danhsachs.length.toString(),
        MaSo: decisionDataQD.Decision_MaSo,
        LuuVT: decisionDataQD.Decision_NguoiTao ? decisionDataQD.Decision_NguoiTao.toString() : "",
        Lop: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Lop_ID : "",
        DanhSach: danhsachs.map((item, index) => {
          return {
            ...item,
            STT: (index + 1).toString(),
          };
        }),
      };

      const modelChiTiet = {
        NganhInTable: decisionDataQD.Decision_Nganh.toUpperCase(),
        Khoa: decisionDataQD.Decision_NienKhoa
          ? decisionDataQD.Decision_NienKhoa.slice(0, decisionDataQD.Decision_NienKhoa.length - 3) +
            (decisionDataQD.Decision_Dot === "" || decisionDataQD.Decision_Dot === null
              ? ""
              : "." + decisionDataQD.Decision_Dot)
          : "",
        SoQuyetDinh: decisionDataQD.Decision_SoQD,
        NganhID: decisionDataQD.Decision_NganhID ?? 0,
        ProcessID: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Process_ID : 0,
        Lop: decisionDataDeTai.length > 0 ? decisionDataDeTai[0].Lop_ID : "",
        Ngay: decisionDataQD.Decision_NgayQD,
        Thang: decisionDataQD.Decision_ThangQD,
        Nam: decisionDataQD.Decision_NamQD,
        DanhSach: danhsachs.map((item, index) => {
          return {
            ...item,
            STT: (index + 1).toString(),
          };
        }),
      };

      const myHeaders = new Headers();
      myHeaders.append("Content-Type", "application/json");
      
      const requestOptions = {
        method: "POST",
        headers: myHeaders,
        body: JSON.stringify(model),
      };
      
      const requestChiTiet = {
        method: "POST",
        headers: myHeaders,
        body: JSON.stringify(modelChiTiet),
      };

      const spaceChar = decisionDataQD.Decision_SoQD ? decisionDataQD.Decision_SoQD.charCodeAt(0) : 32;
      const domain = "https://gendocx.iotsoftvn.com";

      if (typeof JSZip === "undefined") {
        Vue.$toast.error("Không tìm thấy thư viện JSZip để nén file", { position: "top" });
        return;
      }

      const zip = new JSZip();

      try {
        const [blob1, blob2] = await Promise.all([
          ajaxPOSTBlobPromise(`${domain}/api/generate-docx/quyet-dinh-tong-quat`, model),
          ajaxPOSTBlobPromise(`${domain}/api/generate-docx/quyet-dinh-detail`, modelChiTiet),
        ]);
        if (blob1 && blob2) {
          zip.file("QuyetDinh.docx", blob1);
          zip.file("DanhSachChiTiet.docx", blob2);
          const content = await zip.generateAsync({ type: "blob" });
          const a = document.createElement("a");
          a.href = URL.createObjectURL(content);
          a.download = spaceChar === 32 ? "QuyetDinhGiaoDeTai.zip" : `${decisionDataQD.Decision_SoQD} QuyetDinhGiaoDeTai.zip`;
          a.click();
        }
      } catch (error) {
        Vue.$toast.error("Lỗi khi tải file zip", { position: "top" });
      }
    },
  },
	}
</script>
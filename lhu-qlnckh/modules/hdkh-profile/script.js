vueData.rules = {
    required: value => !!value || "Trường này là bắt buộc.",
        year: v =>
            /^\d{4}$/.test(v) && v >= 1900 && v <= 2100 || "Năm phải từ 1900 - 2100"
}
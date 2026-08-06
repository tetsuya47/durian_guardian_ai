import { useState, useEffect, useCallback, useRef, useMemo } from "react";
import {
  Building2,
  Sprout,
  Grid,
  TreePine,
  Edit2,
  Trash2,
  Eye,
  Plus
} from "lucide-react";
import Toolbar from "../../components/common/Toolbar";
import StatCard from "../../components/common/StatCard";
import DataTable from "../../components/common/DataTable";
import Pagination from "../../components/common/Pagination";
import DrawerForm from "../../components/common/DrawerForm";
import RecordDetailDrawer from "../../components/common/RecordDetailDrawer";
import ConfirmDialog from "../../components/common/ConfirmDialog";
import { loadAllPages } from "../../utils/loadAllPages";
import { farmService } from "../../services/farm.service";
import { companyService } from "../../services/company.service";
import { zoneService } from "../../services/zone.service";
import { inspectionService } from "../../services/inspection.service";
import { alertService } from "../../services/alert.service";
import type { Farm } from "../../types/farm";
import type { Company } from "../../types/company";
import type { Zone } from "../../types/zone";
import { formatDateTime } from "../../utils/dateFormatter";

export default function FarmsPage() {
  // Live API data states
  const [farms, setFarms] = useState<Farm[]>([]);
  const [companies, setCompanies] = useState<Company[]>([]);
  const [zones, setZones] = useState<Zone[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);

  // Server-side pagination metadata
  const [totalFarms, setTotalFarms] = useState(0);
  const [totalPages, setTotalPages] = useState(1);

  // Search & Filter local states
  const [searchQuery, setSearchQuery] = useState("");
  const [selectedCompanyId, setSelectedCompanyId] = useState("All");
  const [selectedDistrict, setSelectedDistrict] = useState("All");

  // Pagination local states
  const [currentPage, setCurrentPage] = useState(1);
  const perPage = 20;

  // Drawer Form states
  const [isDrawerOpen, setIsDrawerOpen] = useState(false);
  const [currentFarm, setCurrentFarm] = useState<Farm | null>(null);
  const [formData, setFormData] = useState({
    farm_code: "",
    farm_name: "",
    company_id: "",
    district: "",
    area_hectare: 0,
    address: "",
  });

  // Delete Dialog states
  const [isDialogOpen, setIsDialogOpen] = useState(false);
  const [selectedFarmId, setSelectedFarmId] = useState<string | null>(null);
  const [drawerMode, setDrawerMode] = useState<"create" | "edit">("create");
  const [detailRecord, setDetailRecord] = useState<Farm | null>(null);

  // On-demand detail drawer data (loaded when drawer opens)
  const [detailStats, setDetailStats] = useState<{
    zoneCount: number;
    density: number;
    areaShare: string;
    treeShare: string;
    inspectionCount: number;
    alertCount: number;
  } | null>(null);

  // Build query params and fetch farms from server
  const extractArray = (raw: any): Farm[] => {
    if (Array.isArray(raw)) return raw;
    if (raw && Array.isArray(raw.items)) return raw.items;
    return [];
  };

  // Build query params and fetch farms from server
  const fetchFarms = useCallback(() => {
    setLoading(true);
    setError(null);

    const params: Record<string, string | number> = {
      page: currentPage,
      per_page: perPage,
    };
    if (searchQuery) params.keyword = searchQuery;

    farmService.get<Farm[] & { total?: number; total_pages?: number }>({ params })
      .then((data) => {
        const arr = extractArray(data);
        setFarms(arr);
        setTotalFarms((data as any).total ?? arr.length);
        setTotalPages((data as any).total_pages ?? Math.ceil(((data as any).total ?? arr.length) / perPage));
      })
      .catch((err: unknown) => {
        const msg = err instanceof Error ? err.message : "Không thể tải danh sách trang trại.";
        setError(msg);
      })
      .finally(() => {
        setLoading(false);
      });
  }, [currentPage, searchQuery]);

  const initialLoadDone = useRef(false);

  useEffect(() => {
    if (!initialLoadDone.current) {
      initialLoadDone.current = true;
      setLoading(true);
      setError(null);

      const params: Record<string, string | number> = {
        page: currentPage,
        per_page: perPage,
      };

      Promise.allSettled([
        farmService.get<Farm[] & { total?: number; total_pages?: number }>({ params }),
        loadAllPages(companyService).catch(() => []),
      ])
        .then(([farmsResult, companiesResult]) => {
          if (farmsResult.status === "fulfilled") {
            const farmsData = farmsResult.value;
            const arr = extractArray(farmsData);
            setFarms(arr);
            setTotalFarms((farmsData as any).total ?? arr.length);
            setTotalPages((farmsData as any).total_pages ?? Math.ceil(((farmsData as any).total ?? arr.length) / perPage));
          } else {
            const msg = farmsResult.reason instanceof Error ? farmsResult.reason.message : "Không thể tải danh sách trang trại.";
            setError(msg);
          }
          if (companiesResult.status === "fulfilled" && Array.isArray(companiesResult.value)) {
            setCompanies(companiesResult.value);
          }
        })
        .finally(() => {
          setLoading(false);
        });

      Promise.allSettled([
        loadAllPages(zoneService).catch(() => []),
      ]).then(([zonesResult]) => {
        if (zonesResult.status === "fulfilled" && Array.isArray(zonesResult.value)) setZones(zonesResult.value);
      });

      return;
    }

    fetchFarms();
  }, [currentPage, searchQuery, fetchFarms]);

  const getCompanyName = (id: string) => {
    if (!id) return "—";
    if (companies.length === 0) return "—";
    const company = companies.find((c) => c._id === id || c.company_code === id);
    return company ? company.company_name : "—";
  };

  const DEFAULT_TEO_FARMS: Farm[] = useMemo(() => [
    {
      _id: "farm-teo-01",
      id: "farm-teo-01",
      farm_code: "FRM-EAYONG-01",
      farm_name: "Trang trại Sầu Riêng Sinh Thái Krông Pắc",
      company_id: "comp-teo",
      company_name: "Hợp Tác Xã Sầu Riêng Ea Yông",
      district: "Krông Pắc",
      province: "Đắk Lắk",
      address: "Xã Ea Yông, Huyện Krông Pắc, Tỉnh Đắk Lắk",
      area_hectare: 5.85,
      tree_count: 350,
      status: "Hoạt động",
      created_at: "2026-01-15T08:00:00Z",
      updated_at: "2026-08-01T10:00:00Z",
    },
  ], []);

  const safeFarms = useMemo(() => (Array.isArray(farms) && farms.length > 0 ? farms : DEFAULT_TEO_FARMS), [farms, DEFAULT_TEO_FARMS]);
  const totalAreaAll = useMemo(() => safeFarms.reduce((s, f) => s + (f.area_hectare || 0), 0), [safeFarms]);
  const totalTreesAll = useMemo(() => safeFarms.reduce((s, f) => s + (f.tree_count || 0), 0), [safeFarms]);

  // On-demand: load detail drawer data when a farm is selected
  useEffect(() => {
    if (!detailRecord) {
      setDetailStats(null);
      return;
    }

    const fid = detailRecord._id;
    const area = detailRecord.area_hectare || 0;
    const trees = detailRecord.tree_count || 0;
    const density = area > 0 ? Number((trees / area).toFixed(1)) : 0;
    const areaShare = totalAreaAll > 0 ? ((area / totalAreaAll) * 100).toFixed(1) : "0";
    const treeShare = totalTreesAll > 0 ? ((trees / totalTreesAll) * 100).toFixed(1) : "0";
    const zoneCount = zones.filter((z) => z.farm_id === fid).length;

    Promise.allSettled([
      inspectionService.get({ params: { per_page: 100 } }),
      alertService.get({ params: { keyword: fid, per_page: 1 } }),
    ]).then(([inspResult, alertResult]) => {
      let inspectionCount = 0;
      if (inspResult.status === "fulfilled") {
        const items = Array.isArray(inspResult.value) ? inspResult.value : (inspResult.value as any).items ?? [];
        inspectionCount = items.filter((i: any) => i.farm_id === fid || i.farm === detailRecord.farm_name).length;
      }
      const alertCount = alertResult.status === "fulfilled"
        ? ((alertResult.value as any).total ?? (Array.isArray(alertResult.value) ? alertResult.value.length : 0))
        : 0;

      setDetailStats({ zoneCount, density, areaShare, treeShare, inspectionCount, alertCount });
    });
  }, [detailRecord, totalAreaAll, totalTreesAll, zones]);

  // Set form states for Add Farm
  const handleAddClick = () => {
    setCurrentFarm(null);
    setFormData({
      farm_code: "",
      farm_name: "",
      company_id: companies[0]?._id || "",
      district: "",
      area_hectare: 0,
      address: "",
    });
    setDrawerMode("create");
    setIsDrawerOpen(true);
  };

  // Set form states for Edit Farm
  const handleEditClick = (farm: Farm) => {
    setCurrentFarm(farm);
    setFormData({
      farm_code: farm.farm_code,
      farm_name: farm.farm_name,
      company_id: farm.company_id,
      district: farm.district,
      area_hectare: farm.area_hectare,
      address: farm.address || "",
    });
    setDrawerMode("edit");
    setIsDrawerOpen(true);
  };

  const handleViewClick = (farm: Farm) => {
    setDetailRecord(farm);
  };

  // Trigger Save/Update
  const handleSave = async (e: React.FormEvent) => {
    e.preventDefault();
    const payload = {
      name: formData.farm_name,
      farm_code: formData.farm_code,
      company_id: formData.company_id,
      district: formData.district,
      area: Number(formData.area_hectare) || 0,
      address: formData.address || "",
    };

    try {
      if (currentFarm) {
        // Edit Action
        await farmService.put(currentFarm._id, payload);
      } else {
        // Create Action
        await farmService.post(payload);
      }
      setIsDrawerOpen(false);
      fetchFarms();
    } catch (err: unknown) {
      const msg = err instanceof Error ? err.message : "Lỗi khi lưu dữ liệu trang trại.";
      alert(msg);
    }
  };

  // Handle Delete Click
  const handleDeleteClick = (id: string) => {
    setSelectedFarmId(id);
    setIsDialogOpen(true);
  };

  // Trigger Delete API
  const handleDeleteConfirm = async () => {
    if (selectedFarmId) {
      try {
        await farmService.delete(selectedFarmId);
        fetchFarms();
      } catch (err: unknown) {
        const msg = err instanceof Error ? err.message : "Lỗi khi xóa trang trại.";
        alert(msg);
      } finally {
        setIsDialogOpen(false);
        setSelectedFarmId(null);
      }
    }
  };

  // Dynamically resolve filters from API payload
  const districts = ["All", ...Array.from(new Set(safeFarms.map((f) => f.district).filter(Boolean)))];

  // Client-side filtering for company/district (unsupported by backend)
  const filteredFarms = safeFarms.filter((f) => {
    const matchesCompany = selectedCompanyId === "All" || f.company_id === selectedCompanyId;
    const matchesDistrict = selectedDistrict === "All" || f.district === selectedDistrict;
    return matchesCompany && matchesDistrict;
  });

  // Dynamic statistics aggregations
  const displayTotalFarms = filteredFarms.length || totalFarms;
  const totalAreaHectare = Number(filteredFarms.reduce((sum, f) => sum + (f.area_hectare || 0), 0).toFixed(1));
  const averageAreaHectare = displayTotalFarms > 0 ? Number((totalAreaHectare / displayTotalFarms).toFixed(1)) : 0;
  const totalTrees = filteredFarms.reduce((sum, f) => sum + (f.tree_count || 0), 0);

  // Column mapping
  const columns = [
    { key: "farm_code", label: "Mã trang trại", width: "120px" },
    { key: "farm_name", label: "Tên trang trại", width: "1fr" },
    { key: "address", label: "Địa chỉ / Vị trí vườn", width: "180px" },
    { key: "area_hectare", label: "Diện tích (Ha)", width: "110px" },
    { key: "tree_count", label: "Số cây", width: "90px" },
    { key: "iot_summary", label: "Thiết bị IoT (Key-Value)", width: "220px" },
    { key: "actions", label: "Thao tác", width: "110px", className: "text-right" },
  ];

  // Map database elements to components representation
  const tableRows = useMemo(
    () =>
      filteredFarms.map((row) => {
        const iot = (row as any).iot_summary || {
          total_devices: Math.max(10, Math.round((row.area_hectare || 5) * 15)),
          soil_sensors: Math.max(4, Math.round((row.area_hectare || 5) * 10)),
          weather_stations: 1,
          gateway_hubs: 2,
          smart_valves: 2,
        };
        return {
          farm_code: <span className="font-semibold text-gray-900">{row.farm_code}</span>,
          farm_name: <span className="text-gray-800 font-bold">{row.farm_name}</span>,
          address: <span className="text-gray-600 truncate max-w-[170px] inline-block font-medium">{row.address || row.district || "Đắk Lắk"}</span>,
          area_hectare: <span className="text-gray-700 whitespace-nowrap">{row.area_hectare || 0} Ha</span>,
          tree_count: <span className="text-gray-700 font-semibold">{(row.tree_count || 0).toLocaleString()}</span>,
          iot_summary: (
            <div className="flex flex-col gap-0.5 text-[11px] font-medium text-gray-600">
              <span className="font-extrabold text-emerald-700 bg-emerald-50 px-1.5 py-0.5 rounded w-fit">
                ⚡ Tổng: {iot.total_devices || (iot.soil_sensors + iot.weather_stations + iot.gateway_hubs + iot.smart_valves)} thiết bị
              </span>
              <span className="text-gray-500 text-[10px]">
                🌱 Cảm biến đất: {iot.soil_sensors} • 🌤️ Trạm thời tiết: {iot.weather_stations}
              </span>
            </div>
          ),
          actions: (
            <div className="flex items-center justify-end gap-2 pr-6">
              <button
                onClick={() => handleViewClick(row)}
                type="button"
                title="Xem"
                className="w-9 h-9 rounded-[10px] flex items-center justify-center border border-gray-200 bg-white text-gray-400 hover:bg-[#F8FAFC] hover:text-[#1E8449] hover:border-[#1E8449]/20 transition-all"
              >
                <Eye className="w-4 h-4" />
              </button>
              <button
                onClick={() => handleEditClick(row)}
                type="button"
                aria-label="Edit farm"
                className="w-9 h-9 rounded-[10px] flex items-center justify-center border border-gray-200 bg-white text-gray-400 hover:bg-[#F8FAFC] hover:text-blue-600 hover:border-blue-200 transition-all"
                title="Sửa"
              >
                <Edit2 className="w-4 h-4" />
              </button>
              <button
                onClick={() => handleDeleteClick(row._id)}
                type="button"
                aria-label="Delete farm"
                className="w-9 h-9 rounded-[10px] flex items-center justify-center border border-gray-200 bg-white text-gray-400 hover:bg-[#F8FAFC] hover:text-red-600 hover:border-red-200 transition-all"
                title="Xóa"
              >
                <Trash2 className="w-4 h-4" />
              </button>
            </div>
          ),
        };
      }),
    [filteredFarms, companies]
  );

  // Drawer Footer layout
  const drawerFooter = (
    <div className="flex items-center justify-end gap-3">
      <button
        onClick={() => setIsDrawerOpen(false)}
        type="button"
        className="px-4 py-2 border border-gray-200 rounded-[12px] text-[14px] font-semibold text-gray-700 hover:bg-gray-50 transition-all"
      >
        Hủy
      </button>
      <button
        onClick={handleSave}
        type="button"
        className="px-4 py-2 bg-[#1E8449] text-white rounded-[12px] text-[14px] font-semibold hover:bg-emerald-700 transition-all"
      >
        Lưu
      </button>
    </div>
  );

  const emptyState = error ? (
    <div className="text-red-600 text-sm font-semibold py-6 text-center">
      {error}
    </div>
  ) : (
    <div className="p-8 text-center bg-white rounded-[20px] flex flex-col items-center justify-center gap-3">
      <div className="w-12 h-12 rounded-[16px] bg-emerald-100 text-emerald-700 flex items-center justify-center">
        <Sprout className="w-6 h-6" />
      </div>
      <h3 className="text-base font-extrabold text-gray-900">Bạn Chưa Đăng Ký Trang Trại Nào</h3>
      <p className="text-xs text-gray-500 max-w-md text-center font-medium">
        Khai báo diện tích, số cây và vị trí vườn sầu riêng để hệ thống tự động đề xuất số lượng thiết bị cảm biến IoT phù hợp.
      </p>
      <a
        href="/register-farm"
        className="mt-1 px-5 py-2.5 bg-[#1E8449] hover:bg-emerald-700 text-white font-extrabold text-xs rounded-[12px] shadow-sm transition-all inline-flex items-center gap-2"
      >
        <Plus className="w-4 h-4" />
        🌱 Đăng Ký Vườn Sầu Riêng Mới
      </a>
    </div>
  );

  return (
    <div className="flex flex-col h-full space-y-4">
      <Toolbar
        title="Trang trại của tôi"
        searchValue={searchQuery}
        onSearchChange={(val) => { setSearchQuery(val); setCurrentPage(1); }}
        searchPlaceholder="Tìm kiếm trang trại của tôi..."
      />

      {/* 3. Aggregated Stat Summary Row */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-3">
        <StatCard
          compact
          title="Tổng trang trại"
          value={loading ? "..." : displayTotalFarms.toLocaleString()}
          icon={Sprout}
        />
        <StatCard
          compact
          title="Diện tích TB (Ha)"
          value={loading ? "..." : `${averageAreaHectare} Ha`}
          icon={Building2}
          color="text-blue-600"
        />
        <StatCard
          compact
          title="Tổng diện tích"
          value={loading ? "..." : `${totalAreaHectare} Ha`}
          icon={Grid}
          color="text-amber-600"
        />
        <StatCard
          compact
          title="Tổng cây"
          value={loading ? "..." : totalTrees.toLocaleString()}
          icon={TreePine}
          color="text-indigo-600"
        />
      </div>

      {/* 4. Data Table Grid Layout */}
      <DataTable
        columns={columns}
        rows={tableRows}
        loading={loading}
        emptyState={emptyState}
      />

      {/* 5. Pagination Control Footer */}
      <Pagination
        page={currentPage}
        totalPages={totalPages}
        total={totalFarms}
        perPage={perPage}
        onChange={(p) => setCurrentPage(p)}
      />

      {/* 6. Slide-Out Drawer Form Container */}
      <DrawerForm
        title={drawerMode === "edit" ? "Sửa trang trại" : "Thêm trang trại"}
        open={isDrawerOpen}
        onClose={() => setIsDrawerOpen(false)}
        footer={drawerFooter}
      >
        <form onSubmit={handleSave} className="space-y-4">
          <div>
            <label className="block text-[12px] font-semibold text-gray-500 uppercase tracking-wider mb-1">
              Mã trang trại
            </label>
            <input
              type="text"
              value={formData.farm_code}
              onChange={(e) => setFormData({ ...formData, farm_code: e.target.value })}
              placeholder="VD: FRM-005"
              aria-label="Mã trang trại"
             
              className="w-full px-3 py-2 border border-gray-200 rounded-[10px] bg-white text-[14px] focus:outline-none"
              required
            />
          </div>
          <div>
            <label className="block text-[12px] font-semibold text-gray-500 uppercase tracking-wider mb-1">
              Tên trang trại
            </label>
            <input
              type="text"
              value={formData.farm_name}
              onChange={(e) => setFormData({ ...formData, farm_name: e.target.value })}
              placeholder="VD: Chumphon Gold Hill"
              aria-label="Tên trang trại"
             
              className="w-full px-3 py-2 border border-gray-200 rounded-[10px] bg-white text-[14px] focus:outline-none"
              required
            />
          </div>

          <div>
            <label className="block text-[12px] font-semibold text-gray-500 uppercase tracking-wider mb-1">
              Diện tích (Ha)
            </label>
            <input
              type="number"
              step="any"
              value={formData.area_hectare}
              onChange={(e) => setFormData({ ...formData, area_hectare: Number(e.target.value) || 0 })}
              placeholder="VD: 10.5"
              aria-label="Area in Hectares"
             
              className="w-full px-3 py-2 border border-gray-200 rounded-[10px] bg-white text-[14px] focus:outline-none"
              required
            />
          </div>
          <div>
            <label className="block text-[12px] font-semibold text-gray-500 uppercase tracking-wider mb-1">
              Địa chỉ
            </label>
            <input
              type="text"
              value={formData.address}
              onChange={(e) => setFormData({ ...formData, address: e.target.value })}
              placeholder="VD: Lamae Road"
              aria-label="Address"
             
              className="w-full px-3 py-2 border border-gray-200 rounded-[10px] bg-white text-[14px] focus:outline-none"
            />
          </div>
        </form>
      </DrawerForm>

      <RecordDetailDrawer
        title="Chi tiết trang trại"
        open={!!detailRecord}
        onClose={() => setDetailRecord(null)}
        sections={
          detailRecord && detailStats
            ? [
                {
                  title: "Thông tin chung",
                  fields: [
                    { label: "Mã trang trại", value: detailRecord.farm_code || "—" },
                    { label: "Tên trang trại", value: detailRecord.farm_name || "—" },
                    { label: "Công ty", value: getCompanyName(detailRecord.company_id) },
                  ],
                },
                {
                  title: "Vị trí",
                  fields: [
                    { label: "Quận / Huyện", value: detailRecord.district || "—" },
                  ],
                },
                {
                  title: "Thống kê",
                  fields: [
                    { label: "Diện tích", value: `${detailRecord.area_hectare || 0} ha` },
                    { label: "Số lượng cây", value: (detailRecord.tree_count || 0).toLocaleString() },
                    { label: "Số khu vực", value: detailStats.zoneCount },
                    {
                      label: "Mật độ cây",
                      value: detailStats.density > 0 ? `${detailStats.density} cây/ha` : "—",
                    },
                    { label: "Tỷ trọng diện tích", value: `${detailStats.areaShare}%` },
                    { label: "Tỷ trọng số cây", value: `${detailStats.treeShare}%` },
                  ],
                },
                {
                  title: "Hoạt động",
                  fields: [
                    ...(detailStats.inspectionCount > 0
                      ? [{ label: "Lượt kiểm tra", value: detailStats.inspectionCount }]
                      : []),
                    ...(detailStats.alertCount > 0
                      ? [{ label: "Cảnh báo", value: detailStats.alertCount }]
                      : []),
                  ],
                },
                {
                  title: "Thời gian",
                  fields: [
                    { label: "Ngày tạo", value: formatDateTime(detailRecord.created_at) },
                  ],
                },
              ]
            : []
        }
      />

      {/* 7. Dialog Confirmation Modal */}
      <ConfirmDialog
        title="Xóa trang trại"
        description="Bạn có chắc chắn muốn xóa trang trại này?"
        open={isDialogOpen}
        onConfirm={handleDeleteConfirm}
        onCancel={() => {
          setIsDialogOpen(false);
          setSelectedFarmId(null);
        }}
      />
    </div>
  );
}

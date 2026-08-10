import { BaseService } from "./base.service";

export interface FarmActivityItem {
  _id?: string;
  id?: string;
  title: string;
  activity_type?: string;
  farm_zone?: string;
  scheduled_date?: string;
  assignee?: string;
  priority?: "Cao" | "Trung bình" | "Thường";
  status?: "Chưa bắt đầu" | "Đang thực hiện" | "Hoàn thành";
  note?: string;
  created_at?: string;
}

export interface FarmLogItem {
  _id?: string;
  id?: string;
  code: string;
  submitted_by: string;
  task_name: string;
  zone_name: string;
  submitted_time: string;
  note: string;
  status: "Chờ duyệt" | "Đã phê duyệt" | "Yêu cầu làm lại";
}

class FarmActivityService extends BaseService<FarmActivityItem> {
  constructor() {
    super("/farm-activities");
  }
}

export const farmActivityService = new FarmActivityService();
export default farmActivityService;

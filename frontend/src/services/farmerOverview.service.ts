import api from "../api";
import { BaseService } from "./base.service";
import type { FarmerOverview } from "../types/farmerOverview";

class FarmerOverviewService extends BaseService<FarmerOverview> {
  constructor() {
    super("/admin/users");
  }

  async getOverview(userId: string): Promise<FarmerOverview> {
    const response = await api.get<FarmerOverview>(
      `${this.endpoint}/${userId}/overview`
    );
    return response.data;
  }
}

export const farmerOverviewService = new FarmerOverviewService();
export default farmerOverviewService;

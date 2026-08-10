import { createBrowserRouter, Navigate } from "react-router-dom";
import AppLayout from "@/layouts/AppLayout";
import LoginPage from "@/pages/auth/Login";
import RegisterPage from "@/pages/auth/Register";
import DashboardPage from "@/pages/dashboard/Dashboard";
import FarmDashboardPage from "@/pages/dashboard/FarmDashboard";
import AIChatbotPage from "@/pages/chatbot/AIChatbotPage";
import FarmPerformancePage from "@/pages/performance/FarmPerformancePage";
import FarmStatisticsPage from "@/pages/performance/FarmStatisticsPage";
import CompaniesPage from "@/pages/companies/Companies";
import FarmsPage from "@/pages/farms/Farms";
import ZonesPage from "@/pages/zones/Zones";
import TreesPage from "@/pages/trees/Trees";
import UsersPage from "@/pages/users/Users";
import FarmerOverviewPage from "@/pages/users/FarmerOverview";
import InspectionsPage from "@/pages/inspections/Inspections";
import DetectionResultsPage from "@/pages/detection-results/DetectionResults";
import DiseaseHistoryPage from "@/pages/disease-history/DiseaseHistory";
import AIAlertsPage from "@/pages/alerts/AIAlertsPage";
import AlertsPage from "@/pages/alerts/Alerts";
import DiseasesPage from "@/pages/diseases/Diseases";
import SettingsPage from "@/pages/settings/Settings";
import RegisterFarmPage from "@/pages/farms/RegisterFarmPage";
import IoTSetupGuidePage from "@/pages/iot/IoTSetupGuidePage";
import IoTOrdersPage from "@/pages/iot/IoTOrdersPage";
import IoTManagementPage from "@/pages/iot/IoTManagementPage";
import UserIoTDevicesPage from "@/pages/iot/UserIoTDevicesPage";
import UserHomePage from "@/pages/home/UserHomePage";
import UserCommunityPage from "@/pages/community/UserCommunityPage";
import WorkPlanningPage from "@/pages/farms/WorkPlanningPage";
import WorkerAssignmentPage from "@/pages/farms/WorkerAssignmentPage";
import LogApprovalPage from "@/pages/farms/LogApprovalPage";
import FarmReportsPage from "@/pages/farms/FarmReportsPage";
import ProtectedRoute from "./ProtectedRoute";
import { useAuth } from "@/hooks/useAuth";

function RootRedirect() {
  const { user } = useAuth();
  const isAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";
  return <Navigate to={isAdmin ? "/dashboard" : "/home"} replace />;
}

function HomeRouteGuard() {
  const { user } = useAuth();
  const isAdmin = user?.role === "Admin" || user?.role === "ADMIN" || user?.role === "System Admin";
  if (isAdmin) {
    return <Navigate to="/dashboard" replace />;
  }
  return <UserHomePage />;
}

export const router = createBrowserRouter([
  {
    path: "/login",
    element: <LoginPage />,
  },
  {
    path: "/register",
    element: <RegisterPage />,
  },
  {
    path: "/",
    element: (
      <ProtectedRoute>
        <AppLayout />
      </ProtectedRoute>
    ),
    children: [
      {
        index: true,
        element: <RootRedirect />,
      },
      {
        path: "home",
        element: <HomeRouteGuard />,
      },
      {
        path: "community",
        element: <UserCommunityPage />,
      },
      {
        path: "dashboard",
        element: <DashboardPage />,
      },
      {
        path: "ai-chatbot",
        element: <Navigate to="/dashboard" replace />,
      },
      {
        path: "farm-performance",
        element: <FarmPerformancePage />,
      },
      {
        path: "dashboard/farm/:farmId",
        element: <FarmDashboardPage />,
      },
      {
        path: "register-farm",
        element: <RegisterFarmPage />,
      },
      {
        path: "work-planning",
        element: <WorkPlanningPage />,
      },
      {
        path: "worker-assignment",
        element: <WorkerAssignmentPage />,
      },
      {
        path: "log-approval",
        element: <LogApprovalPage />,
      },
      {
        path: "farm-reports",
        element: <FarmReportsPage />,
      },
      {
        path: "farm-statistics",
        element: <FarmStatisticsPage />,
      },
      {
        path: "iot-setup-guide",
        element: <IoTSetupGuidePage />,
      },
      {
        path: "iot-shop",
        element: <IoTOrdersPage />,
      },
      {
        path: "my-iot-devices",
        element: <Navigate to="/dashboard" replace />,
      },
      {
        path: "companies",
        element: <CompaniesPage />,
      },
      {
        path: "farms",
        element: <FarmsPage />,
      },
      {
        path: "zones",
        element: <ZonesPage />,
      },
      {
        path: "trees",
        element: <TreesPage />,
      },
      {
        path: "users",
        element: <UsersPage />,
      },
      {
        path: "users/:user_id",
        element: <FarmerOverviewPage />,
      },
      {
        path: "inspections",
        element: <InspectionsPage />,
      },
      {
        path: "detection-results",
        element: <DetectionResultsPage />,
      },
      {
        path: "disease-history",
        element: <DiseaseHistoryPage />,
      },
      {
        path: "alerts",
        element: <AlertsPage />,
      },
      {
        path: "ai-alerts",
        element: <AIAlertsPage />,
      },
      {
        path: "iot-orders",
        element: <IoTManagementPage />,
      },
      {
        path: "iot-management",
        element: <IoTManagementPage />,
      },
      {
        path: "diseases",
        element: <DiseasesPage />,
      },
      {
        path: "settings",
        element: <SettingsPage />,
      },
    ],
  },
  {
    path: "*",
    element: <Navigate to="/login" replace />,
  },
]);

import { createBrowserRouter, Navigate } from "react-router-dom";
import AppLayout from "@/layouts/AppLayout";
import LoginPage from "@/pages/auth/Login";
import RegisterPage from "@/pages/auth/Register";
import DashboardPage from "@/pages/dashboard/Dashboard";
import FarmDashboardPage from "@/pages/dashboard/FarmDashboard";
import AIChatbotPage from "@/pages/chatbot/AIChatbotPage";
import FarmPerformancePage from "@/pages/performance/FarmPerformancePage";
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
import ProtectedRoute from "./ProtectedRoute";

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
        element: <Navigate to="/dashboard" replace />,
      },
      {
        path: "home",
        element: <UserHomePage />,
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
        element: <AIChatbotPage />,
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
        path: "iot-setup-guide",
        element: <IoTSetupGuidePage />,
      },
      {
        path: "iot-shop",
        element: <IoTOrdersPage />,
      },
      {
        path: "my-iot-devices",
        element: <UserIoTDevicesPage />,
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

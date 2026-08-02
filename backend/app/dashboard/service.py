from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories import (
    FarmRepository,
    FarmPerformanceRepository,
    FarmTargetRepository,
    HarvestRepository,
    NotificationRepository,
    SeasonRepository,
    TreeRepository,
)
from app.schemas import (
    AlertBrief,
    DashboardOut,
    DetectionBrief,
    KpiData,
    RiskTrendItem,
    SystemOverview,
    WidgetsOut,
    WidgetInspection,
    WidgetDetection,
    WidgetPriorityTree,
    WidgetAlert,
    WidgetAlertCounts,
    WidgetFarmOption,
    WidgetZoneOption,
)
from app.dashboard.dto import FarmPerformanceDTO
from app.schemas.dashboard import (
    FarmDashboardOut,
    FarmDashboardKpi,
    FarmHealthDistribution,
    FarmHeatmapTree,
    FarmZone,
    FarmYield,
    FarmAlertSummary,
)

logger = logging.getLogger(__name__)


class DashboardService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.farm_repo = FarmRepository(db)
        self.tree_repo = TreeRepository(db)
        self.notification_repo = NotificationRepository(db)
        self.season_repo = SeasonRepository(db)
        self.farm_perf_repo = FarmPerformanceRepository(db)
        self.farm_target_repo = FarmTargetRepository(db)
        self.harvest_repo = HarvestRepository(db)

    async def _get_zone_ids_for_farms(self, farm_ids: list[str]) -> list[ObjectId]:
        farm_oids = [ObjectId(fid) for fid in farm_ids if ObjectId.is_valid(fid)]
        if not farm_oids:
            return []
        zone_ids = []
        async for z in self.db["zones"].find({"farm_id": {"$in": farm_oids}}):
            zone_ids.append(z["_id"])
        return zone_ids

    async def get_dashboard(self, user_id: str) -> DashboardOut:
        farms, _ = await self.farm_repo.list_by_owner(user_id, page=1, per_page=100)
        total_farms = len(farms)
        farm_ids = [f["id"] for f in farms]

        zone_ids = await self._get_zone_ids_for_farms(farm_ids)

        healthy_filter = {"$or": [{"health_status": {"$in": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$in": ["Healthy", "Khỏe mạnh"]}}]}
        diseased_filter = {"$or": [{"health_status": {"$nin": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$nin": ["Healthy", "Khỏe mạnh"]}}]}
        high_risk_filter = {"$or": [{"health_status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ", "$options": "i"}}, {"status": {"$regex": "Phytophthora|High Risk|Nguy cơ cao|thối|xì mủ", "$options": "i"}}]}

        if zone_ids:
            zone_oid_filter = {"zone_id": {"$in": zone_ids}}
            total_trees, healthy_trees, diseased_trees, high_risk_trees = await asyncio.gather(
                self.db["trees"].count_documents(zone_oid_filter),
                self.db["trees"].count_documents({"$and": [zone_oid_filter, healthy_filter]}),
                self.db["trees"].count_documents({"$and": [zone_oid_filter, diseased_filter]}),
                self.db["trees"].count_documents({"$and": [zone_oid_filter, high_risk_filter]}),
            )
        else:
            total_trees = 0
            healthy_trees = 0
            diseased_trees = 0
            high_risk_trees = 0

        if total_trees == 0:
            total_trees, healthy_trees, diseased_trees, high_risk_trees = await asyncio.gather(
                self.db["trees"].count_documents({}),
                self.db["trees"].count_documents(healthy_filter),
                self.db["trees"].count_documents(diseased_filter),
                self.db["trees"].count_documents(high_risk_filter),
            )

        recent_detection, alerts, risk_trend, system_overview = await asyncio.gather(
            self._get_recent_detections(),
            self._get_alerts(),
            self._get_risk_trend(),
            self._get_system_overview(),
        )

        return DashboardOut(
            kpi=KpiData(
                total_farms=total_farms,
                total_trees=total_trees,
                healthy_trees=healthy_trees,
                diseased_trees=diseased_trees,
                high_risk_trees=high_risk_trees,
            ),
            system_overview=system_overview,
            recent_detection=recent_detection,
            alerts=alerts,
            risk_trend=risk_trend,
        )

    async def _get_system_overview(self) -> SystemOverview:
        (inspection_today, ai_detection_today, new_alerts_today,
         inspected_ids, latest_doc) = await asyncio.gather(
            self.db["inspections"].count_documents({}),
            self.db["detection_results"].count_documents({}),
            self.db["alerts"].count_documents({}),
            self.db["detection_results"].distinct("inspection_id"),
            self.db["alerts"].find_one(
                sort=[("created_at", -1)],
                projection={"created_at": 1},
            ),
        )

        pending_review = await self.db["inspections"].count_documents({
            "_id": {"$nin": inspected_ids},
        })

        updated_at = latest_doc["created_at"] if latest_doc else datetime.now(timezone.utc)

        return SystemOverview(
            inspection_today=inspection_today,
            ai_detection_today=ai_detection_today,
            new_alerts_today=new_alerts_today,
            pending_review=pending_review,
            updated_at=updated_at,
        )

    async def _get_recent_detections(self) -> list[DetectionBrief]:
        pipeline = [
            {"$sort": {"created_at": -1}},
            {"$limit": 10},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree",
                }
            },
            {"$unwind": {"path": "$tree", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 0,
                    "disease": {"$ifNull": ["$disease_name", {"$ifNull": ["$disease", "Khỏe mạnh"]}]},
                    "confidence": 1,
                    "severity": {"$ifNull": ["$severity", "Mild"]},
                    "tree_code": {"$ifNull": ["$tree.tree_code", "SR-M01"]},
                    "image_url": {"$ifNull": ["$image_url", ""]},
                    "created_at": 1,
                }
            },
        ]
        cursor = self.db["disease_history"].aggregate(pipeline)
        result = []
        async for doc in cursor:
            result.append(
                DetectionBrief(
                    disease=doc["disease"],
                    confidence=doc.get("confidence", 0.0),
                    severity=doc.get("severity", "Mild"),
                    tree_code=doc.get("tree_code", "SR-M01"),
                    image_url=doc.get("image_url", ""),
                    created_at=doc["created_at"],
                )
            )
        if not result:
            cursor2 = self.db["detection_results"].aggregate(pipeline)
            async for doc in cursor2:
                result.append(
                    DetectionBrief(
                        disease=doc.get("disease", "Khỏe mạnh"),
                        confidence=doc.get("confidence", 0.0),
                        severity=doc.get("severity", "Mild"),
                        tree_code=doc.get("tree_code", "SR-M01"),
                        image_url=doc.get("image_url", ""),
                        created_at=doc["created_at"],
                    )
                )
        return result

    async def _get_alerts(self) -> list[AlertBrief]:
        docs, _ = await self.notification_repo.list(
            page=1, per_page=20, sort=[("created_at", -1)]
        )
        return [
            AlertBrief(
                title=doc.get("title", doc.get("alert_type", "Alert")),
                content=doc.get("content", f"System warning priority: {doc.get('priority', 'N/A')}"),
                created_at=doc["created_at"],
            )
            for doc in docs
        ]

    async def _get_risk_trend(self) -> list[RiskTrendItem]:
        pipeline = [
            {
                "$project": {
                    "date_str": {"$dateToString": {"format": "%Y-%m-%d", "date": "$date"}},
                    "risk_val": {
                        "$switch": {
                            "branches": [
                                {"case": {"$eq": ["$priority", "High"]}, "then": 0.8},
                                {"case": {"$eq": ["$priority", "Medium"]}, "then": 0.5},
                                {"case": {"$eq": ["$priority", "Low"]}, "then": 0.2}
                            ],
                            "default": 0.0
                        }
                    }
                }
            },
            {
                "$group": {
                    "_id": "$date_str",
                    "avg_risk": {"$avg": "$risk_val"}
                }
            },
            {"$sort": {"_id": 1}},
            {"$limit": 14},
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            items.append(
                RiskTrendItem(date=str(doc["_id"]), avg_risk=round(doc["avg_risk"], 4))
            )
        return items

    async def get_heatmap(self) -> dict:
        total = await self.db["trees"].count_documents({})
        pipeline = [
            {"$sort": {"tree_code": 1}},
            {"$project": {"tree_code": 1, "zone_id": 1, "status": 1}},
            {
                "$lookup": {
                    "from": "zones",
                    "localField": "zone_id",
                    "foreignField": "_id",
                    "as": "zone_info",
                }
            },
            {"$unwind": {"path": "$zone_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "zone_info.farm_id",
                    "foreignField": "_id",
                    "as": "farm_info",
                }
            },
            {"$unwind": {"path": "$farm_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "tree_id": {"$toString": "$_id"},
                    "tree_code": {"$ifNull": ["$tree_code", ""]},
                    "zone_id": {
                        "$cond": {
                            "if": {"$ne": ["$zone_id", None]},
                            "then": {"$toString": "$zone_id"},
                            "else": "",
                        }
                    },
                    "zone_name": {"$ifNull": ["$zone_info.zone_name", ""]},
                    "farm_id": {
                        "$cond": {
                            "if": {"$ne": ["$zone_info.farm_id", None]},
                            "then": {"$toString": ["$zone_info.farm_id"]},
                            "else": "",
                        }
                    },
                    "status": {"$ifNull": ["$status", "Healthy"]},
                }
            },
        ]
        cursor = self.db["trees"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            items.append(doc)
        return {"total": total, "data": items}

    async def get_widgets(self) -> WidgetsOut:
        (
            widget_inspections,
            widget_detections,
            widget_priority_trees,
            alert_counts,
            widget_alerts,
            farm_options,
            zone_options,
        ) = await asyncio.gather(
            self._get_widget_inspections(),
            self._get_widget_detections(),
            self._get_widget_priority_trees(),
            self._get_alert_counts(),
            self._get_widget_alerts(),
            self._get_farm_options(),
            self._get_zone_options(),
        )

        return WidgetsOut(
            inspections=widget_inspections,
            detections=widget_detections,
            priorityTrees=widget_priority_trees,
            alertCounts=alert_counts,
            alerts=widget_alerts,
            farms=farm_options,
            zones=zone_options,
        )

    async def _get_widget_inspections(self) -> list[WidgetInspection]:
        pipeline = [
            {"$sort": {"inspection_date": -1}},
            {"$limit": 50},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "zones",
                    "localField": "tree_info.zone_id",
                    "foreignField": "_id",
                    "as": "zone_info",
                }
            },
            {"$unwind": {"path": "$zone_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "zone_info.farm_id",
                    "foreignField": "_id",
                    "as": "farm_info",
                }
            },
            {"$unwind": {"path": "$farm_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "users",
                    "localField": "inspector_id",
                    "foreignField": "_id",
                    "as": "user_info",
                }
            },
            {"$unwind": {"path": "$user_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "detection_results",
                    "let": {"tree_oid": "$tree_id"},
                    "pipeline": [
                        {"$match": {"$expr": {"$eq": ["$tree_id", "$$tree_oid"]}}},
                        {"$sort": {"created_at": -1}},
                        {"$limit": 1},
                    ],
                    "as": "latest_detection",
                }
            },
            {"$unwind": {"path": "$latest_detection", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 1,
                    "tree_code": {"$ifNull": ["$tree_info.tree_code", ""]},
                    "farm_name": {"$ifNull": ["$farm_info.farm_name", ""]},
                    "zone_name": {"$ifNull": ["$zone_info.zone_name", ""]},
                    "inspector_name": {"$ifNull": ["$user_info.full_name", ""]},
                    "inspection_date": 1,
                    "created_at": 1,
                    "status": 1,
                    "predicted_disease": 1,
                    "detection_confidence": {"$ifNull": ["$latest_detection.confidence", 0]},
                }
            },
        ]
        cursor = self.db["inspections"].aggregate(pipeline)
        rows = []
        async for doc in cursor:
            risk = round(float(doc.get("detection_confidence", 0)))
            if risk >= 90:
                action = "Khám hôm nay"
            elif risk >= 80:
                action = "Theo dõi"
            else:
                action = "Xem xét"

            raw_date = doc.get("inspection_date") or doc.get("created_at")
            time_str = raw_date.strftime("%d/%m/%Y %H:%M") if hasattr(raw_date, "strftime") else str(raw_date) if raw_date else "—"

            rows.append(
                WidgetInspection(
                    id=str(doc["_id"]),
                    time=time_str,
                    treeCode=doc.get("tree_code", "—"),
                    farm=doc.get("farm_name", "—"),
                    zone=doc.get("zone_name", "—"),
                    disease=doc.get("predicted_disease") or "Chưa phát hiện",
                    risk=risk,
                    inspector=doc.get("inspector_name", "—"),
                    status=doc.get("status", "—"),
                    action=action,
                )
            )
        return rows

    async def _get_widget_detections(self) -> list[WidgetDetection]:
        pipeline = [
            {"$sort": {"created_at": -1}},
            {"$limit": 100},
            {
                "$lookup": {
                    "from": "inspections",
                    "localField": "inspection_id",
                    "foreignField": "_id",
                    "as": "inspection",
                }
            },
            {"$unwind": {"path": "$inspection", "preserveNullAndEmptyArrays": False}},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "inspection.tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "zones",
                    "localField": "tree_info.zone_id",
                    "foreignField": "_id",
                    "as": "zone_info",
                }
            },
            {"$unwind": {"path": "$zone_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "zone_info.farm_id",
                    "foreignField": "_id",
                    "as": "farm_info",
                }
            },
            {"$unwind": {"path": "$farm_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 1,
                    "tree_code": {"$ifNull": ["$tree_info.tree_code", ""]},
                    "prediction": {"$ifNull": ["$prediction", ""]},
                    "confidence": 1,
                    "farm_name": {"$ifNull": ["$farm_info.farm_name", ""]},
                    "zone_name": {"$ifNull": ["$zone_info.zone_name", ""]},
                    "image_url": {"$ifNull": ["$image_url", None]},
                    "created_at": 1,
                }
            },
        ]
        cursor = self.db["detection_results"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            confidence = float(doc.get("confidence", 0))
            severity = (
                "Severe" if confidence >= 80
                else "Moderate" if confidence >= 50
                else "Mild"
            )
            items.append(
                WidgetDetection(
                    id=str(doc["_id"]),
                    treeCode=doc.get("tree_code", "—"),
                    disease=doc.get("prediction", "—"),
                    confidence=confidence,
                    severity=severity,
                    farm=doc.get("farm_name", "—"),
                    zone=doc.get("zone_name", "—"),
                    imageUrl=doc.get("image_url"),
                    createdAt=str(doc.get("created_at", "")),
                )
            )
        return items

    async def _get_widget_priority_trees(self) -> list[WidgetPriorityTree]:
        pipeline = [
            {"$sort": {"created_at": -1}},
            {
                "$lookup": {
                    "from": "inspections",
                    "localField": "inspection_id",
                    "foreignField": "_id",
                    "as": "inspection",
                }
            },
            {"$unwind": {"path": "$inspection", "preserveNullAndEmptyArrays": False}},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "inspection.tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "zones",
                    "localField": "tree_info.zone_id",
                    "foreignField": "_id",
                    "as": "zone_info",
                }
            },
            {"$unwind": {"path": "$zone_info", "preserveNullAndEmptyArrays": True}},
            {
                "$lookup": {
                    "from": "farms",
                    "localField": "zone_info.farm_id",
                    "foreignField": "_id",
                    "as": "farm_info",
                }
            },
            {"$unwind": {"path": "$farm_info", "preserveNullAndEmptyArrays": True}},
            {
                "$group": {
                    "_id": "$inspection.tree_id",
                    "latest_detection": {"$first": "$$ROOT"},
                }
            },
            {"$replaceRoot": {"newRoot": "$latest_detection"}},
            {"$sort": {"confidence": -1}},
            {"$limit": 5},
            {
                "$project": {
                    "_id": 0,
                    "tree_code": {"$ifNull": ["$tree_info.tree_code", "Chưa có dữ liệu"]},
                    "confidence": 1,
                    "farm_name": {"$ifNull": ["$farm_info.farm_name", "—"]},
                    "zone_name": {"$ifNull": ["$zone_info.zone_name", "—"]},
                    "prediction": {"$ifNull": ["$prediction", "Khỏe mạnh"]},
                }
            },
        ]
        cursor = self.db["detection_results"].aggregate(pipeline)
        items = []
        rank = 1
        async for doc in cursor:
            confidence = int(round(float(doc.get("confidence", 0))))
            status = (
                "Nghiêm trọng" if confidence >= 90
                else "Cảnh báo" if confidence >= 80
                else "Khỏe mạnh"
            )
            items.append(
                WidgetPriorityTree(
                    id=rank,
                    treeId=doc.get("tree_code", "—"),
                    riskScore=confidence,
                    status=status,
                    farm=doc.get("farm_name", "—"),
                    zone=doc.get("zone_name", "—"),
                    disease=doc.get("prediction", "Khỏe mạnh"),
                )
            )
            rank += 1
        return items

    async def _get_alert_counts(self) -> WidgetAlertCounts:
        pipeline = [
            {
                "$group": {
                    "_id": {"$toLower": {"$ifNull": ["$priority", ""]}},
                    "count": {"$sum": 1},
                }
            }
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        counts = {"high": 0, "medium": 0, "low": 0}
        async for doc in cursor:
            key = doc["_id"]
            if key in counts:
                counts[key] = doc["count"]
        return WidgetAlertCounts(**counts)

    async def _get_widget_alerts(self) -> list[WidgetAlert]:
        pipeline = [
            {"$sort": {"created_at": -1}},
            {"$limit": 20},
            {
                "$project": {
                    "_id": 1,
                    "tree_id": {"$ifNull": ["$tree_id", ""]},
                    "priority": {"$ifNull": ["$priority", ""]},
                    "title": {"$ifNull": ["$title", "Alert"]},
                    "content": {"$ifNull": ["$content", ""]},
                    "created_at": 1,
                }
            },
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            created = doc.get("created_at")
            created_str = created.strftime("%d/%m/%Y %H:%M") if hasattr(created, "strftime") else str(created) if created else ""
            items.append(
                WidgetAlert(
                    id=str(doc["_id"]),
                    treeId=str(doc.get("tree_id", "")),
                    priority=doc.get("priority", ""),
                    title=doc.get("title", "Alert"),
                    content=doc.get("content", ""),
                    createdAt=created_str,
                )
            )
        return items

    async def _get_farm_options(self) -> list[WidgetFarmOption]:
        cursor = self.db["farms"].find({}, {"farm_name": 1}).sort("farm_name", 1)
        items = []
        async for doc in cursor:
            items.append(
                WidgetFarmOption(id=str(doc["_id"]), name=doc.get("farm_name", ""))
            )
        return items

    async def _get_zone_options(self) -> list[WidgetZoneOption]:
        cursor = self.db["zones"].find({}, {"zone_name": 1}).sort("zone_name", 1)
        items = []
        async for doc in cursor:
            items.append(
                WidgetZoneOption(id=str(doc["_id"]), name=doc.get("zone_name", ""))
            )
        return items

    # ── Farm Dashboard ────────────────────────────────────────────────

    async def _get_latest_farm_season(self, farm_oid: ObjectId) -> dict | None:
        return await self.season_repo.get_latest_by_farm(farm_oid)

    async def get_farm_dashboard(self, farm_id: str) -> FarmDashboardOut:
        farm_oid = ObjectId(farm_id) if ObjectId.is_valid(farm_id) else farm_id

        zone_ids = []
        async for z in self.db["zones"].find({"farm_id": farm_oid}, {"_id": 1}):
            zone_ids.append(z["_id"])

        tree_filter = {"zone_id": {"$in": zone_ids}} if zone_ids else {"_id": {"$in": []}}

        (
            total_trees,
            healthy_count,
            monitoring_count,
            diseased_count,
            high_risk_tree_ids,
            zones_raw,
            season,
        ) = await asyncio.gather(
            self.db["trees"].count_documents(tree_filter),
            self.db["trees"].count_documents({**tree_filter, "$or": [{"health_status": {"$in": ["Healthy", "Khỏe mạnh"]}}, {"status": {"$in": ["Healthy", "Khỏe mạnh"]}}]}),
            self.db["trees"].count_documents({**tree_filter, "$or": [{"health_status": {"$in": ["Monitoring", "Đang theo dõi"]}}, {"status": {"$in": ["Monitoring", "Đang theo dõi"]}}]}),
            self.db["trees"].count_documents({**tree_filter, "$or": [{"health_status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}, {"status": {"$in": ["Diseased", "Bệnh", "Bị bệnh"]}}]}),
            self.db["alerts"].distinct("tree_id", {"priority": "High", "tree_id": {"$in": []}}) if not zone_ids else self._get_high_risk_tree_ids_for_farm(zone_ids),
            self._get_farm_zones(farm_oid, zone_ids),
            self._get_latest_farm_season(farm_oid),
        )

        high_risk_count = len(high_risk_tree_ids)

        healthy_pct = round((healthy_count / total_trees) * 100, 1) if total_trees > 0 else 0.0

        heatmap = await self._get_farm_heatmap(zone_ids)

        alert_summary = await self._get_farm_alert_summary(zone_ids)

        kpi_kwargs: dict = {}
        yield_kwargs: dict = {}
        season_name: str | None = None
        season_year: int | None = None

        if season:
            season_oid = ObjectId(season["id"])
            season_name = season.get("season_name")
            season_year = season.get("season_year")

            perf, targets_obj, harvest = await asyncio.gather(
                self.farm_perf_repo.get_by_farm_and_season(farm_oid, season_oid),
                self.farm_target_repo.get_by_farm_and_season(farm_oid, season_oid),
                self.harvest_repo.get_latest_by_farm(farm_oid),
            )

            if perf:
                kpi_kwargs["farm_score"] = perf.get("farm_score")
                kpi_kwargs["health_score"] = perf.get("health_score")
                kpi_kwargs["yield_score"] = perf.get("yield_score")
                kpi_kwargs["risk_index"] = perf.get("risk_index")
                kpi_kwargs["overall_status"] = perf.get("overall_status")

            if targets_obj:
                kpi_kwargs["target_yield"] = targets_obj.get("target_yield")
                kpi_kwargs["target_tree_health"] = targets_obj.get("target_tree_health")
                kpi_kwargs["target_disease_rate"] = targets_obj.get("target_disease_rate")

            if harvest:
                yield_kwargs["yield_kg"] = harvest.get("yield_kg")
                yield_kwargs["average_weight"] = harvest.get("average_weight")
                yield_kwargs["grade_a"] = harvest.get("grade_a")
                yield_kwargs["grade_b"] = harvest.get("grade_b")
                yield_kwargs["grade_c"] = harvest.get("grade_c")
                yield_kwargs["selling_price"] = harvest.get("selling_price")
                yield_kwargs["total_revenue"] = harvest.get("total_revenue")
                yield_kwargs["buyer"] = harvest.get("buyer")

        yield_data = FarmYield(
            estimated_yield="--",
            avg_yield_per_tree="--",
            avg_yield_per_hectare="--",
            **yield_kwargs,
        )

        return FarmDashboardOut(
            kpi=FarmDashboardKpi(
                total_trees=total_trees,
                total_zones=len(zones_raw),
                healthy_percent=healthy_pct,
                high_risk_trees=high_risk_count,
                estimated_yield="--",
                **kpi_kwargs,
            ),
            health_distribution=FarmHealthDistribution(
                healthy=healthy_count,
                monitoring=monitoring_count,
                diseased=diseased_count,
            ),
            heatmap=heatmap,
            zones=zones_raw,
            yield_data=yield_data,
            alerts=alert_summary,
            season_name=season_name,
            season_year=season_year,
        )

    async def _load_farm_performance_data(self, farm_oid: ObjectId) -> dict | None:
        try:
            season = await self.db["seasons"].find_one(
                {"farm_id": farm_oid, "status": "active"},
                projection={"_id": 1},
            )
            if not season:
                season = await self.db["seasons"].find_one(
                    {"farm_id": farm_oid},
                    sort=[("season_year", -1), ("created_at", -1)],
                    projection={"_id": 1},
                )
            if not season:
                return None

            season_oid = season["_id"]
            perf, targets_obj, harvest = await asyncio.gather(
                self.db["farm_performance"].find_one(
                    {"farm_id": farm_oid, "season_id": season_oid},
                    projection={"farm_score": 1, "health_score": 1, "overall_status": 1},
                ),
                self.db["farm_targets"].find_one(
                    {"farm_id": farm_oid, "season_id": season_oid},
                    projection={"target_yield": 1},
                ),
                self.db["harvests"].find_one(
                    {"farm_id": farm_oid},
                    sort=[("harvest_date", -1)],
                    projection={"yield_kg": 1},
                ),
            )

            result: dict = {}
            if perf:
                result["farm_score"] = perf.get("farm_score")
                result["health_score"] = perf.get("health_score")
                result["overall_status"] = perf.get("overall_status")
            if targets_obj:
                result["target_yield"] = targets_obj.get("target_yield")
            if harvest:
                result["yield_kg"] = harvest.get("yield_kg")
            return result
        except Exception:
            logger.warning("Skipping farm %s due to error", farm_oid, exc_info=True)
            return None

    async def get_farm_performance(self, user_id: str, farm_id: str | None = None) -> FarmPerformanceDTO:
        if farm_id:
            farm_oid = ObjectId(farm_id) if ObjectId.is_valid(farm_id) else None
            if not farm_oid:
                return FarmPerformanceDTO(total_farms=0)

            farm = await self.db["farms"].find_one(
                {"_id": farm_oid},
                projection={"_id": 1},
            )
            if not farm:
                return FarmPerformanceDTO(total_farms=0)

            result = await self._load_farm_performance_data(farm_oid)

            if not result:
                return FarmPerformanceDTO(total_farms=1)

            farm_score = result.get("farm_score")
            health_score = result.get("health_score")
            target_yield = result.get("target_yield")
            yield_kg = result.get("yield_kg")

            total_target = round(target_yield, 1) if target_yield else None
            total_actual = round(yield_kg, 1) if yield_kg else None
            yield_pct = round((total_actual / total_target) * 100, 1) if total_target and total_actual else None

            if farm_score is not None:
                if farm_score >= 70:
                    status: str | None = "Tốt"
                elif farm_score >= 50:
                    status = "Cảnh báo"
                else:
                    status = "Nghiêm trọng"
            else:
                status = "Chưa đánh giá"

            return FarmPerformanceDTO(
                average_farm_score=farm_score,
                farms_evaluated=1 if farm_score is not None else 0,
                total_farms=1,
                healthy_percent=health_score,
                total_target_yield=total_target,
                total_actual_yield=total_actual,
                yield_achievement_pct=yield_pct,
                overall_status=status,
            )

        farms, _ = await self.farm_repo.list_by_owner(user_id, page=1, per_page=100)
        total_farms = len(farms)

        if not farms:
            return FarmPerformanceDTO(total_farms=0)

        sem = asyncio.Semaphore(5)

        async def _process_farm(farm: dict) -> dict | None:
            async with sem:
                farm_oid = ObjectId(farm["id"]) if ObjectId.is_valid(farm["id"]) else None
                if not farm_oid:
                    return None
                return await self._load_farm_performance_data(farm_oid)

        tasks = [_process_farm(farm) for farm in farms]
        results = await asyncio.gather(*tasks)
        results = [r for r in results if r is not None]

        farm_scores = [
            r["farm_score"] for r in results if r.get("farm_score") is not None
        ]
        health_scores = [
            r["health_score"] for r in results if r.get("health_score") is not None
        ]
        target_yields = [
            r["target_yield"] for r in results if r.get("target_yield") is not None
        ]
        actual_yields = [
            r["yield_kg"] for r in results if r.get("yield_kg") is not None
        ]

        avg_score = round(sum(farm_scores) / len(farm_scores), 1) if farm_scores else None
        avg_health = round(sum(health_scores) / len(health_scores), 1) if health_scores else None
        total_target = round(sum(target_yields), 1) if target_yields else None
        total_actual = round(sum(actual_yields), 1) if actual_yields else None
        yield_pct = (
            round((total_actual / total_target) * 100, 1)
            if total_target and total_actual
            else None
        )

        if avg_score is not None:
            if avg_score >= 70:
                status: str | None = "Tốt"
            elif avg_score >= 50:
                status = "Cảnh báo"
            else:
                status = "Nghiêm trọng"
        elif total_farms > 0:
            status = "Chưa đánh giá"
        else:
            status = None

        return FarmPerformanceDTO(
            average_farm_score=avg_score,
            farms_evaluated=len(farm_scores),
            total_farms=total_farms,
            healthy_percent=avg_health,
            total_target_yield=total_target,
            total_actual_yield=total_actual,
            yield_achievement_pct=yield_pct,
            overall_status=status,
        )

    async def _get_high_risk_tree_ids_for_farm(self, zone_ids: list[ObjectId]) -> list:
        pipeline = [
            {"$match": {"priority": "High"}},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": False}},
            {"$match": {"tree_info.zone_id": {"$in": zone_ids}}},
            {"$group": {"_id": "$tree_id"}},
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        results = []
        async for doc in cursor:
            results.append(doc["_id"])
        return results

    async def _get_farm_zones(self, farm_oid, zone_ids: list[ObjectId]) -> list[FarmZone]:
        if not zone_ids:
            return []

        pipeline = [
            {"$match": {"_id": {"$in": zone_ids}}},
            {"$sort": {"zone_code": 1}},
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "_id",
                    "foreignField": "zone_id",
                    "as": "trees",
                }
            },
            {
                "$project": {
                    "zone_name": 1,
                    "tree_count": {"$size": "$trees"},
                    "healthy_count": {
                        "$size": {
                            "$filter": {
                                "input": "$trees",
                                "cond": {
                                    "$or": [
                                        {"$in": ["$$this.health_status", ["Healthy", "Khỏe mạnh"]]},
                                        {"$in": ["$$this.status", ["Healthy", "Khỏe mạnh"]]}
                                    ]
                                },
                            }
                        }
                    },
                    "diseased_count": {
                        "$size": {
                            "$filter": {
                                "input": "$trees",
                                "cond": {
                                    "$or": [
                                        {"$in": ["$$this.health_status", ["Diseased", "Bị bệnh", "Bệnh", "High Risk"]]},
                                        {"$in": ["$$this.status", ["Diseased", "Bị bệnh", "Bệnh", "High Risk"]]}
                                    ]
                                },
                            }
                        }
                    },
                }
            },
        ]
        cursor = self.db["zones"].aggregate(pipeline)
        zones = []
        async for doc in cursor:
            tc = doc.get("tree_count", 0)
            dc = doc.get("diseased_count", 0)
            if tc > 0 and (dc / tc) > 0.3:
                risk = "Nghiêm trọng"
            elif tc > 0 and (dc / tc) > 0.1:
                risk = "Cảnh báo"
            else:
                risk = "Bình thường"
            zones.append(
                FarmZone(
                    id=str(doc["_id"]),
                    name=doc.get("zone_name", ""),
                    tree_count=tc,
                    healthy_count=doc.get("healthy_count", 0),
                    diseased_count=dc,
                    risk_level=risk,
                )
            )
        return zones

    async def _get_farm_heatmap(self, zone_ids: list[ObjectId]) -> list[FarmHeatmapTree]:
        if not zone_ids:
            return []

        pipeline = [
            {"$match": {"zone_id": {"$in": zone_ids}}},
            {"$sort": {"tree_code": 1}},
            {"$project": {"tree_code": 1, "zone_id": 1, "status": 1}},
            {
                "$lookup": {
                    "from": "zones",
                    "localField": "zone_id",
                    "foreignField": "_id",
                    "as": "zone_info",
                }
            },
            {"$unwind": {"path": "$zone_info", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "tree_id": {"$toString": "$_id"},
                    "tree_code": {"$ifNull": ["$tree_code", ""]},
                    "zone_id": {"$toString": "$zone_id"},
                    "zone_name": {"$ifNull": ["$zone_info.zone_name", ""]},
                    "status": {"$ifNull": ["$status", "Healthy"]},
                }
            },
        ]
        cursor = self.db["trees"].aggregate(pipeline)
        items = []
        async for doc in cursor:
            items.append(FarmHeatmapTree(**doc))
        return items

    async def _get_farm_alert_summary(self, zone_ids: list[ObjectId]) -> FarmAlertSummary:
        if not zone_ids:
            return FarmAlertSummary(high=0, medium=0, low=0)

        pipeline = [
            {
                "$lookup": {
                    "from": "trees",
                    "localField": "tree_id",
                    "foreignField": "_id",
                    "as": "tree_info",
                }
            },
            {"$unwind": {"path": "$tree_info", "preserveNullAndEmptyArrays": False}},
            {"$match": {"tree_info.zone_id": {"$in": zone_ids}}},
            {
                "$group": {
                    "_id": {"$toLower": {"$ifNull": ["$priority", ""]}},
                    "count": {"$sum": 1},
                }
            },
        ]
        cursor = self.db["alerts"].aggregate(pipeline)
        counts = {"high": 0, "medium": 0, "low": 0}
        async for doc in cursor:
            key = doc["_id"]
            if key in counts:
                counts[key] = doc["count"]
        return FarmAlertSummary(**counts)

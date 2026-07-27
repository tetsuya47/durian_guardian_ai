from __future__ import annotations

import asyncio
import logging
from datetime import datetime, timezone

from bson import ObjectId
from motor.motor_asyncio import AsyncIOMotorDatabase

from app.repositories import (
    FarmRepository,
    NotificationRepository,
    TreeRepository,
)
from app.schemas import AlertBrief, DashboardOut, DetectionBrief, KpiData, RiskTrendItem, SystemOverview

logger = logging.getLogger(__name__)


class DashboardService:
    def __init__(self, db: AsyncIOMotorDatabase) -> None:
        self.db = db
        self.farm_repo = FarmRepository(db)
        self.tree_repo = TreeRepository(db)
        self.notification_repo = NotificationRepository(db)

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

        zone_ids, high_risk_trees = await asyncio.gather(
            self._get_zone_ids_for_farms(farm_ids),
            self.db["alerts"].distinct("tree_id", {"priority": "High"}),
        )
        high_risk_trees = len(high_risk_trees)

        if zone_ids:
            zone_oid_filter = {"zone_id": {"$in": zone_ids}}
            total_trees, healthy_trees, diseased_trees = await asyncio.gather(
                self.db["trees"].count_documents(zone_oid_filter),
                self.db["trees"].count_documents({**zone_oid_filter, "status": "Healthy"}),
                self.db["trees"].count_documents({**zone_oid_filter, "status": "Diseased"}),
            )
        else:
            total_trees = 0
            healthy_trees = 0
            diseased_trees = 0

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
        today_start = datetime.now(timezone.utc).replace(hour=0, minute=0, second=0, microsecond=0)

        (inspection_today, ai_detection_today, new_alerts_today,
         inspected_ids, latest_doc) = await asyncio.gather(
            self.db["inspections"].count_documents({
                "inspection_date": {"$gte": today_start},
            }),
            self.db["detection_results"].count_documents({
                "created_at": {"$gte": today_start},
            }),
            self.db["alerts"].count_documents({
                "created_at": {"$gte": today_start},
            }),
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
                    "as": "tree",
                }
            },
            {"$unwind": {"path": "$tree", "preserveNullAndEmptyArrays": True}},
            {
                "$project": {
                    "_id": 0,
                    "disease": {"$ifNull": ["$prediction", "N/A"]},
                    "confidence": 1,
                    "severity": {
                        "$switch": {
                            "branches": [
                                {"case": {"$gte": ["$confidence", 80.0]}, "then": "Severe"},
                                {"case": {"$gte": ["$confidence", 50.0]}, "then": "Moderate"},
                            ],
                            "default": "Mild",
                        }
                    },
                    "tree_code": {"$ifNull": ["$tree.tree_code", "N/A"]},
                    "created_at": 1,
                }
            },
        ]
        cursor = self.db["detection_results"].aggregate(pipeline)
        result = []
        async for doc in cursor:
            result.append(
                DetectionBrief(
                    disease=doc["disease"],
                    confidence=doc["confidence"],
                    severity=doc["severity"],
                    tree_code=doc["tree_code"],
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
        items, total = await self.tree_repo.find_all_heatmap()
        return {"total": total, "data": items}

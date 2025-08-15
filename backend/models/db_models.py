from sqlalchemy import func, Column, Integer, String, Float, ForeignKey, UniqueConstraint, Date, Time, Text, DateTime
from sqlalchemy.orm import relationship

from db.database import Base

class PlaceModel(Base):
    __tablename__ = 'place'

    id = Column(Integer, primary_key=True)
    name = Column(String(255), index=True, nullable=False)
    address = Column(String(500), index=True, nullable=False)
    x_position = Column(String(100), nullable=False)
    y_position = Column(String(100), nullable=False)
    image_url = Column(String(500), nullable=False)

    bookmark = relationship("BookmarkModel", back_populates="place")

class BookmarkModel(Base):
    __tablename__ = 'bookmark'

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('user.id'), nullable=False)
    place_id = Column(Integer, ForeignKey('place.id'), nullable=False)
    place = relationship("PlaceModel", back_populates="bookmark")
    user = relationship("UserModel", back_populates="bookmark")

    __table_args__ = (
        UniqueConstraint('user_id', 'place_id', name='uq_user_place_id'),
    )


class RecordModel(Base):
    __tablename__ = 'record'

    id = Column(Integer, primary_key=True)
    user_id = Column(Integer, ForeignKey('user.id'), nullable=False)
    place_id = Column(Integer, ForeignKey('place.id'), nullable=False)

    record_date = Column(Date, index=True, nullable=False)
    start_time = Column(Time, nullable=False)
    end_time = Column(Time, nullable=False)
    pool_length = Column(Float, nullable=False)
    swim_distance = Column(Integer, nullable=False)
    memo = Column(Text, nullable=False)
    created_at = Column(DateTime, default=func.now())
    updated_at = Column(DateTime, default=func.now(), onupdate=func.now())

    place = relationship("PlaceModel")

class UserModel(Base):
    __tablename__ = 'user'

    id = Column(Integer, primary_key=True)
    nickname = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    password = Column(String(100), nullable=False)
    bookmark = relationship("BookmarkModel", back_populates="user")


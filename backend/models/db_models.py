from sqlalchemy import Column, Integer, String, Float, ForeignKey, UniqueConstraint
from sqlalchemy.orm import relationship
from db.database import Base

class PlaceModel(Base):
    __tablename__ = 'place'

    id = Column(Integer, primary_key=True)
    name = Column(String(255), index=True, nullable=False)
    address = Column(String(500), index=True, nullable=False)
    x_position = Column(Float, nullable=False)
    y_position = Column(Float, nullable=False)

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

class UserModel(Base):
    __tablename__ = 'user'

    id = Column(Integer, primary_key=True)
    nickname = Column(String(50), unique=True, nullable=False)
    email = Column(String(100), unique=True, nullable=False)
    bookmark = relationship("BookmarkModel", back_populates="user")


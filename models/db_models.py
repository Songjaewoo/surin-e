from sqlalchemy import Column, Integer, String, Float, ForeignKey
from db.database import Base

class Place(Base):
    __tablename__ = 'place'

    id = Column(Integer, primary_key=True)
    name = Column(String(255), index=True, nullable=False)
    address = Column(String(500), index=True, nullable=False)
    x_position = Column(Float, nullable=False)
    y_position = Column(Float, nullable=False)

class bookmark(Base):
    __tablename__ = 'bookmark'

    id = Column(Integer, primary_key=True)
    place_id = Column(Integer, ForeignKey('place.id'), nullable=False)

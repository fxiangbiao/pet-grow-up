package com.petgrowup.auth.mapper;

import com.mybatisflex.core.BaseMapper;
import com.petgrowup.auth.entity.User;
import org.apache.ibatis.annotations.Mapper;

@Mapper
public interface UserMapper extends BaseMapper<User> {
}

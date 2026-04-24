package com.bsg.docviz.service;

import org.springframework.stereotype.Repository;

import java.util.Arrays;
import java.util.List;

@Repository
public class MockTagsRepository {

    public List<String> findAllTags() {
        return Arrays.asList("Java", "Oracle", "SQL", "Spring", "Angular", "React", "Python", "COBOL");
    }
}

#include <ctype.h>
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define true 1
#define false 0

typedef struct {
  uint8_t jmp_instruction[3];
  uint8_t oem_identifier[8];
  uint16_t bytes_per_sector;
  uint8_t sectors_per_cluster;
  uint16_t reserved_sector_count;
  uint8_t fat_table_count;
  uint16_t dir_entry_count;
  uint16_t total_sector_count;
  uint8_t media_descriptor_type;
  uint16_t sectors_per_fat;
  uint16_t sectors_per_track;
  uint16_t head_count;
  uint32_t hidden_sector_count;
  uint32_t large_sector_count;
  // ebr fat12
  uint8_t ebr_drive_number;
  uint8_t _reserved;
  uint8_t ebr_signature;
  uint8_t ebr_volume_id[4];
  uint8_t ebr_volume_label_str[11];
  uint8_t ebr_system_id_str[8];
} __attribute__((packed)) BootSector;

typedef struct {
  uint8_t file_name[11];
  uint8_t attribute;
  uint8_t _reserved;
  uint8_t created_time_tenth;
  uint16_t created_time;
  uint16_t created_date;
  uint16_t last_accessed_date;
  uint16_t cluster_high;
  uint16_t last_modification_time;
  uint16_t last_modification_date;
  uint16_t cluster_low;
  uint32_t file_size;
} __attribute__((packed)) DirectoryEntry;

BootSector global_boot_sector;
uint8_t *global_fat_buffer;
uint32_t root_dir_end; // where root dir ends and data region starts
DirectoryEntry *global_dir_entries = NULL;

int read_boot_sector(FILE *disk) {
  return fread(&global_boot_sector, sizeof(BootSector), 1, disk) > 0;
}

int read_sectors(FILE *disk, uint32_t lba, uint32_t count, void *buffer_out) {
  int ok = true;
  ok = ok &&
       (fseek(disk, lba * global_boot_sector.bytes_per_sector, SEEK_SET) == 0);
  ok = ok && (fread(buffer_out, global_boot_sector.bytes_per_sector, count,
                    disk) == count);
  return ok;
}

int read_fat(FILE *disk) {
  global_fat_buffer = (uint8_t *)malloc(global_boot_sector.sectors_per_fat *
                                        global_boot_sector.bytes_per_sector);
  return read_sectors(disk, global_boot_sector.reserved_sector_count,
                      global_boot_sector.sectors_per_fat, global_fat_buffer);
}

int read_root_dir(FILE *disk) {
  uint32_t lba =
      global_boot_sector.reserved_sector_count +
      global_boot_sector.sectors_per_fat * global_boot_sector.fat_table_count;
  uint32_t size = sizeof(DirectoryEntry) * global_boot_sector.dir_entry_count;
  uint32_t sectors = size / global_boot_sector.bytes_per_sector;
  if (size % sectors > 0) {
    sectors++;
  }
  root_dir_end = lba + sectors;
  global_dir_entries =
      (DirectoryEntry *)malloc(global_boot_sector.bytes_per_sector * sectors);
  return read_sectors(disk, lba, sectors, global_dir_entries);
}

DirectoryEntry *find_file(const char *file_name) {
  for (size_t i = 0; i < global_boot_sector.dir_entry_count; i++) {
    if (memcmp(global_dir_entries[i].file_name, file_name, 11) == 0) {
      return &global_dir_entries[i];
    }
  }
  return NULL;
}

int readfile(DirectoryEntry *file_entry, FILE *disk, uint8_t *buffer_out) {
  int ok = true;
  uint16_t current_cluster = file_entry->cluster_low;
  // lba for file = data_region_begin + (cluster - 2) * sectors_per_cluster
  // file is stored in clusters
  do {
    uint32_t lba = root_dir_end + (current_cluster - 2) *
                                      global_boot_sector.sectors_per_cluster;
    ok = ok && read_sectors(disk, lba, global_boot_sector.sectors_per_cluster,
                            buffer_out);
    buffer_out += global_boot_sector.sectors_per_cluster *
                  global_boot_sector.bytes_per_sector; // move to next cluster
    uint32_t fat_index = current_cluster * 3 / 2;
    if ((current_cluster & 0x01) == 0) {
      current_cluster = (*(uint16_t *)(global_fat_buffer + fat_index)) &
                        0x0FFF; // lower 12 bits

      /*
       * example
       *
       * - fat
       *   f0 ff ff ff 4f 00 05 60 00
       *
       * - cluster
       *   ff0 fff fff 004 005 006
       *
       */
    } else {
      current_cluster = (*(uint16_t *)(global_fat_buffer + fat_index)) >> 4;
    }
  } while (ok && current_cluster < 0xFF8);
  return ok;
}

int main(int argc, char **argv) {
  if (argc < 3) {
    printf("args for %s: disk_img_name file_name\n", argv[0]);
    return -1;
  }

  FILE *disk = fopen(argv[1], "rb");
  if (disk == 0) {
    fprintf(stderr, "failed to read disk %s", argv[1]);
    return -1;
  }

  if (read_boot_sector(disk) == false) {
    fprintf(stderr, "failed to read boot sector!");
    return -2;
  }

  if (read_fat(disk) == false) {
    fprintf(stderr, "failed to read fat!");
    free(global_fat_buffer);
    return -3;
  }

  if (read_root_dir(disk) == false) {
    fprintf(stderr, "failed to read dir!");
    free(global_fat_buffer);
    free(global_dir_entries);
    return -4;
  }

  DirectoryEntry *found_entry = find_file(argv[2]);
  if (found_entry == NULL) {
    fprintf(stderr, "file %s not found in directory entries!", argv[2]);
    free(global_fat_buffer);
    free(global_dir_entries);
    return -5;
  }

  uint8_t *content_buffer = (uint8_t *)malloc(
      global_dir_entries->file_size + global_boot_sector.bytes_per_sector);

  if (readfile(found_entry, disk, content_buffer) == false) {
    fprintf(stderr, "file %s cannot be read!", argv[2]);
    free(global_fat_buffer);
    free(global_dir_entries);
    free(content_buffer);
    return -5;
  }

  for (size_t i = 0; i < found_entry->file_size; i++) {
    if (isprint(content_buffer[i])) {
      fputc(content_buffer[i], stdout);
    } else {
      printf("(%02x)", content_buffer[i]);
    }
  }
  printf("\n");

  free(global_fat_buffer);
  free(global_dir_entries);
  free(content_buffer);
  return 0;
}

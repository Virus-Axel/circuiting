use std::f64::consts::PI;

use solana_program::{
    account_info::{next_account_info, AccountInfo},
    entrypoint::ProgramResult,
    msg,
    program_error::ProgramError,
    pubkey::Pubkey,
    system_instruction::{self, transfer},
    sysvar::{rent::Rent, Sysvar, clock::Clock},
    program::invoke,
};

use nalgebra::{vector, Vector2, Rotation2, UnitComplex};

use super::token_handler::{
    give_token,
    burn_token,
};

const OWNER_SIZE: usize = 32;
const HEALTH_SIZE: usize = 2;
const SPEED_SIZE: usize = 1;
const LOCATION_SIZE: usize = 24;
const TIMESTAMP_SIZE: usize = 8;
const MAX_BOARD_WIDTH: u8 = 16;
const MAX_BOARD_HEIGHT: u8 = 32;
const DATA_SIZE_PER_UNIT: u8 = 3; // Component type, input 1, component specific data,

const ARRAY_OFFSET: usize = OWNER_SIZE + HEALTH_SIZE + SPEED_SIZE + LOCATION_SIZE + TIMESTAMP_SIZE;
const TIMESTAMP_OFFSET: usize = OWNER_SIZE + HEALTH_SIZE + SPEED_SIZE + LOCATION_SIZE;
const LOCATION_OFFSET: usize = OWNER_SIZE + HEALTH_SIZE + SPEED_SIZE;

const ENEMY_DAMAGE_PER_SECOND: f64 = 1.0;

const ROCKET_SPEED: f64 = 90.0;

fn update_timestamp(data: &mut [u8], timestamp: i64){
    data[TIMESTAMP_OFFSET..(TIMESTAMP_OFFSET+TIMESTAMP_SIZE)].copy_from_slice(&timestamp.to_le_bytes());
}

fn get_timestamp(data: &[u8]) -> i64{
    i64::from_le_bytes(data[TIMESTAMP_OFFSET..(TIMESTAMP_OFFSET+TIMESTAMP_SIZE)].try_into().unwrap())
}

fn get_mass_center(data: &[u8]) -> nalgebra::Vector2<f64>{
	let mut amount = 0;
	let mut mass_total_x = 0.0;
    let mut mass_total_y = 0.0;
	for x in 0..MAX_BOARD_WIDTH{
		for y in 0..MAX_BOARD_HEIGHT{
			if get_pcb_array_element(data, x, y) != 0{
				amount += 1;
				mass_total_x += x as f64;
                mass_total_y += y as f64;
            }
        }
    }
	
	Vector2::new(mass_total_x / (amount as f64), mass_total_y / (amount as f64))
}

fn get_force_from_pos(data: &[u8], x: u8, y: u8) -> (f64, f64){
	if is_engine_on_at(data, x, y){
		return (0.0, 1.0);
    }
	else{
		return (0.0, 0.0);
    }
}

fn get_velocity(data: &[u8]) -> nalgebra::Vector2<f64>{
	let mc = get_mass_center(data);

    msg!("mc: {}, {}", mc.x, mc.y);

    let mut result_force = nalgebra::vector![0.0, 0.0];

	for x in 0..MAX_BOARD_WIDTH{
		for y in 0..MAX_BOARD_HEIGHT{
			if is_engine_on_at(data, x, y){
				let engine_force = get_force_from_pos(data, x, y);
                let engine_force_vec = nalgebra::vector![engine_force.0, engine_force.1];
                let angle_to_centrum = vector![1.0, 0.0].angle(&(mc - vector![x as f64, y as f64]));

				//let angle_to_centrum = mc.angle(&nalgebra::vector![x as f64, y as f64]);
                msg!("x, y = {}, {}", x, y);
                msg!("angle to centrum: {}", angle_to_centrum);
				let rotational_force = engine_force_vec.magnitude() * angle_to_centrum.cos();
				let velocity_force = engine_force_vec.magnitude() * angle_to_centrum.sin();

                result_force += vector!(rotational_force, velocity_force);
            }
        }
    }
	
	result_force
}

fn update_position_after_ms(data: &mut[u8], delta_time: i64, velocity: Vector2<f64>){
    const ANGLE_PER_MS: f64 = 0.24;

    let angle = f64::from_le_bytes(data[(LOCATION_OFFSET+16)..(LOCATION_OFFSET+24)].try_into().unwrap());
    let mut radius = 0.0;

    let pos = nalgebra::vector![
        f64::from_le_bytes(data[LOCATION_OFFSET..(LOCATION_OFFSET+8)].try_into().unwrap()),
        f64::from_le_bytes(data[(LOCATION_OFFSET+8)..(LOCATION_OFFSET+16)].try_into().unwrap()),
    ];

    msg!("vel: {}, {}", velocity.x, velocity.y);

    if velocity.x.abs() > 0.0001{
        radius = velocity.magnitude() * velocity.y / velocity.x;

        let circle_length = radius*2.0*PI;
        
        let change_angle = (ANGLE_PER_MS * (delta_time as f64)) / circle_length;
        
        let circulate_around_point = - (Rotation2::new(angle) * nalgebra::vector![ROCKET_SPEED, 0.0] * radius);

        let new_pos = pos - circulate_around_point + UnitComplex::new(change_angle) * circulate_around_point;

        let mut new_angle = angle;
        if velocity.x < 0.0{
            new_angle += change_angle;
        }
        else{
            new_angle += change_angle;
        }

        while new_angle > PI * 2.0{
            new_angle -= PI * 2.0;
        }
        while new_angle < 0.0{
            new_angle += PI * 2.0;
        }

        set_circulation_point(data, new_pos, new_angle);
    }

    else if velocity.y.abs() > 0.0001{
        let change = Rotation2::new(angle) * vector![ 0.0, -(velocity.y * ROCKET_SPEED * 0.5 * ANGLE_PER_MS)] * (delta_time as f64);
        msg!("change is: {}, {}", change.x, change.y);
        set_circulation_point(data, pos + change, angle);
    }
}

fn get_position(data: &[u8]) -> Vector2<f64>{
    vector![
        f64::from_le_bytes(data[LOCATION_OFFSET..(LOCATION_OFFSET+8)].try_into().unwrap()),
        f64::from_le_bytes(data[(LOCATION_OFFSET+8)..(LOCATION_OFFSET+16)].try_into().unwrap())
    ]
}

fn set_circulation_point(data: &mut[u8], pos: Vector2<f64>, angle: f64){
    data[LOCATION_OFFSET..(LOCATION_OFFSET+8)].copy_from_slice(&pos.x.to_le_bytes());
    data[(LOCATION_OFFSET+8)..(LOCATION_OFFSET+16)].copy_from_slice(&pos.y.to_le_bytes());
    data[(LOCATION_OFFSET+16)..(LOCATION_OFFSET+24)].copy_from_slice(&angle.to_le_bytes());
}

fn update_guns(data: &mut [u8], delta_time: i64) -> u8{
    let mut highest_cooldown = 0;
    for x in 0..MAX_BOARD_WIDTH{
        for y in 0..MAX_BOARD_HEIGHT{
            if get_pcb_array_element(data, x, y) == 2{
                let cooldown = get_pcb_array_meta_data(data, x, y);
                if cooldown > 0{
                    if cooldown > highest_cooldown{
                        highest_cooldown = 255 - cooldown;
                    }
                    if delta_time > cooldown as i64{
                        set_pcb_array_meta_data(data, x, y, 0);
                    }
                    else{
                        set_pcb_array_meta_data(data, x, y, cooldown - delta_time as u8);
                    }
                }
            }
        }
    }
    return 255 - highest_cooldown;
}

fn process_ship(data: &mut [u8]) -> ProgramResult{
    let current_time = Clock::get().unwrap().unix_timestamp;
    let delta_time = current_time - get_timestamp(data);

    let velocity = get_velocity(data);
    update_position_after_ms(data, delta_time, velocity);
    if velocity.y != 0.0{
        let seconds_since_last_shot = update_guns(data, delta_time);
        const CALM_TIME: u8 = 30;
        if seconds_since_last_shot > CALM_TIME{
            let damage = get_damage_from_delta_time(delta_time - CALM_TIME as i64);
            damage_and_death_check(data, damage)?;
        }
        else{
            let damage = get_damage_from_delta_time(delta_time - seconds_since_last_shot as i64);
            damage_and_death_check(data, damage)?;
        }
    }

    update_timestamp(data, current_time);
    Ok(())
}

fn damage_and_death_check(data: &mut [u8], damage: u32) -> ProgramResult{
    let current_health = get_health(data);
    
    if (current_health as u32) < damage{
        set_health(data, 0);
        //shut_all_engines_off(data)?;
    }
    else{
        set_health(data, current_health - damage as u8);
    }
    Ok(())
}

fn get_damage_from_delta_time(delta_time: i64) -> u32{
    if delta_time < 0{
        return 0;
    }
    msg!("the float: {}", ((delta_time as f64) * ENEMY_DAMAGE_PER_SECOND));
    ((delta_time as f64) * ENEMY_DAMAGE_PER_SECOND) as u32
}

fn is_engine_on_at(data: &[u8], x: u8, y: u8) -> bool{
    if get_pcb_array_element(data, x, y) == 3{
        if get_pcb_array_meta_data(data, x, y) == 1{
            msg!("engine on at {}, {}", x, y);
            return true;
        }
    }
    false
}

fn shut_all_engines_off(data: &mut[u8]) -> ProgramResult{
    for x in 0..MAX_BOARD_WIDTH{
        for y in 0..MAX_BOARD_HEIGHT{
            // Check if engine
            if is_engine_on_at(data, x, y){
                toggle_engine_at(data, x, y)?;
            }
        }
    }
    Ok(())
}

fn spacecraft_account_size() -> usize {
    (MAX_BOARD_HEIGHT as usize) * (MAX_BOARD_WIDTH as usize) * (DATA_SIZE_PER_UNIT as usize)
        + LOCATION_SIZE
        + SPEED_SIZE
        + HEALTH_SIZE
        + OWNER_SIZE
}

fn toggle_engine_at(data: &mut [u8], x: u8, y: u8) -> ProgramResult{
    let existing_value = get_pcb_array_meta_data(data, x, y);
    if existing_value == 1{
        msg!("DEACTIVATING engine at {}, {}", x, y);
        set_pcb_array_meta_data(data, x, y, 0)
    }
    else{
        msg!("ACTIVATING");
        set_pcb_array_meta_data(data, x, y, 1);
    }

    Ok(())
}

fn fire_gun_at(data: &mut [u8], x: u8, y: u8) -> ProgramResult{
    let existing_value = get_pcb_array_meta_data(data, x, y);
    if existing_value != 0{
        msg!("Gun not ready");
        return Err(ProgramError::InvalidInstructionData);
    }
    else{
        set_pcb_array_meta_data(data, x, y, 255);
    }

    Ok(())
}

fn set_health(data: &mut [u8], health :u8){
    data[OWNER_SIZE] = health;
}

fn get_health(data: &[u8]) -> u8{
    data[OWNER_SIZE]
}

fn set_max_health(data: &mut [u8], max_health :u8){
    data[OWNER_SIZE+1] = max_health;
}

fn get_max_health(data: &[u8]) -> u8{
    data[OWNER_SIZE+1]
}

fn set_pcb_array_element(data: &mut [u8], x: u8, y: u8, value: u8){
    data[ARRAY_OFFSET + ((y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)) * (DATA_SIZE_PER_UNIT as usize)] = value;
}

fn get_pcb_array_element(data: &[u8], x: u8, y: u8) -> u8{
    data[ARRAY_OFFSET + ((y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)) * (DATA_SIZE_PER_UNIT as usize)]
}

fn get_pcb_array_meta_data(data: &[u8], x: u8, y: u8) -> u8{
    data[ARRAY_OFFSET + ((y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)) * (DATA_SIZE_PER_UNIT as usize) + 2]
}

fn set_pcb_array_meta_data(data: &mut [u8], x: u8, y: u8, meta_data: u8){
    data[ARRAY_OFFSET + ((y as usize) * (MAX_BOARD_WIDTH as usize) + (x as usize)) * (DATA_SIZE_PER_UNIT as usize) + 2] = meta_data;
}

pub fn create_spacecraft_account<'a>(
    accounts: &'a [AccountInfo<'a>],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let payer_account = next_account_info(accounts_iter)?;
    let new_account = next_account_info(accounts_iter)?;
    let new_kp = next_account_info(accounts_iter)?;

    let system_program = next_account_info(accounts_iter)?;

    invoke(
        &transfer(&payer_account.key, &new_kp.key, 100000000),
        &[payer_account.clone(), new_kp.clone(), system_program.clone()],
    )?;

    let account_size = spacecraft_account_size();
    if new_account.data_len() != account_size{
        ;// TODO(Virax): enable before deploying.
        //return Err(ProgramError::AccountDataTooSmall);
    }
    if new_account.owner.to_string() != crate::ID{
        return Err(ProgramError::IllegalOwner);
    }

    let mut new_data = new_account.try_borrow_mut_data().unwrap();

    // TODO(Virax): Remove when not testing stuff.
    for i in 0..(new_data.len()){
        new_data[i] = 0;
    }

    new_data[0..32].copy_from_slice(&payer_account.key.to_bytes());

    const MAX_HEALTH: u8 = 32;
    set_max_health(&mut new_data, MAX_HEALTH);
    set_health(&mut new_data, MAX_HEALTH);

    let current_time = Clock::get().unwrap().unix_timestamp;

    set_circulation_point(&mut new_data, vector![0.0, 0.0], 0.0);
    update_timestamp(&mut new_data, current_time);

    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 0, 3);
    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 1, 1);
    set_pcb_array_element(&mut new_data, MAX_BOARD_WIDTH / 2, 2, 1);

    Ok(())
}

pub fn upgrade_health<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let mapping_account = next_account_info(accounts_iter)?;

    Ok(())
}

pub fn add_component<'a>(
    program_id: &Pubkey,
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;

    let token_mint = next_account_info(accounts_iter)?;
    let token_account = next_account_info(accounts_iter)?;
    let mint_authority = next_account_info(accounts_iter)?;

    let token_program = next_account_info(accounts_iter)?;

    burn_token(program_id, token_mint, token_account, token_program, sender_account, 1)?;
    
    let mut data = play_account.try_borrow_mut_data().unwrap();
    set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], instruction_data[3]);

    Ok(())
}

pub fn remove_component<'a>(
    accounts: &'a [AccountInfo<'a>],
    instruction_data: &[u8],
) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;

    // TODO(Virax): return a token here.
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    let existing_component = get_pcb_array_element(&mut data, instruction_data[1], instruction_data[2]);
    if existing_component > 1{
        set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], 1);
    }
    else if existing_component == 1{
        set_pcb_array_element(&mut data, instruction_data[1], instruction_data[2], 0);
    }
    else{
        return Err(ProgramError::InvalidInstructionData);
    }

    Ok(())
}

pub fn activate_component<'a>(accounts: &'a [AccountInfo<'a>], instruction_data: &[u8]) -> ProgramResult {
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    process_ship(&mut data)?;

    let existing_component = get_pcb_array_element(&data, instruction_data[1], instruction_data[2]);
    msg!("EXISTING_COMPONENT IS: {}", existing_component);
    match existing_component{
        2 => fire_gun_at(&mut data, instruction_data[1], instruction_data[2]),
        3 => toggle_engine_at(&mut data, instruction_data[1], instruction_data[2]),
        _ => Err(ProgramError::InvalidInstructionData),
    }?;

    Ok(())
}

pub fn sync_spaceship_account<'a>(accounts: &'a [AccountInfo<'a>]) -> ProgramResult{
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    process_ship(&mut data)?;

    Ok(())
}

pub fn claim_score<'a>(program_id: &Pubkey, accounts: &'a [AccountInfo<'a>]) -> ProgramResult{
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;
    
    let token_mint = next_account_info(accounts_iter)?;
    let token_account = next_account_info(accounts_iter)?;

    let authority = next_account_info(accounts_iter)?;

    let rent = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;

    let mut data = play_account.try_borrow_mut_data().unwrap();

    process_ship(&mut data)?;

    if data[32] == 0{
        return Err(ProgramError::InvalidAccountData);
    }

    give_token(program_id, token_mint, token_account, token_program, authority, rent, 1)?;

    /*let pos = get_position(&mut data);
    for i in 0..31{
        let pos2 = vector![(data[i] as f64) / 255.0, (data[i+1] as f64) / 255.0];
        let distance_to_present = (pos2 - pos).magnitude();
        const DISTANCE_THRESHOLD: f64 = 1.0;
        if distance_to_present < DISTANCE_THRESHOLD{

        } 
    }*/

    Ok(())
}

pub fn claim_reward_and_respawn<'a>(program_id: &Pubkey, accounts: &'a [AccountInfo<'a>]) -> ProgramResult{
    let accounts_iter = &mut accounts.iter();

    // Get the accounts
    let _sender_account = next_account_info(accounts_iter)?;
    let play_account = next_account_info(accounts_iter)?;

    let board_mint = next_account_info(accounts_iter)?;
    let engine_mint = next_account_info(accounts_iter)?;
    let gun_mint = next_account_info(accounts_iter)?;

    let board_token_acc = next_account_info(accounts_iter)?;
    let engine_token_acc = next_account_info(accounts_iter)?;
    let gun_token_acc = next_account_info(accounts_iter)?;

    let mint_authority = next_account_info(accounts_iter)?;

    let rent = next_account_info(accounts_iter)?;
    let token_program = next_account_info(accounts_iter)?;
    
    let mut data = play_account.try_borrow_mut_data().unwrap();

    let death_pos = get_position(&data);
    let random_enough = death_pos.x * death_pos.y * 1000000.0;

    let timestamp = get_timestamp(&data);

    let (mint,  token_account) = match (timestamp + random_enough.abs() as i64) % 3{
        0 => (board_mint, board_token_acc),
        1 => (engine_mint, engine_token_acc),
        2 => (gun_mint, gun_token_acc),
        _ => panic!(),
    };

    give_token(program_id, mint, token_account, token_program, mint_authority, rent, 1)?;

    process_ship(&mut data)?;

    if get_health(&data) != 0{
        return Err(ProgramError::InvalidAccountData);
    }

    set_circulation_point(&mut data, vector![0.0, 0.0], 0.0);
    let max_health = get_max_health(&data);
    set_health(&mut data, max_health);
    shut_all_engines_off(&mut data)?;

    Ok(())
}